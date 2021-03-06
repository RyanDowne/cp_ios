//
//  ProfileViewController.m
//  candpiosapp
//
//  Created by Stojce Slavkovski on 29.6.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "ProfileViewController.h"
#import "PushModalViewControllerFromLeftSegue.h"
#import "GRMustacheTemplate.h"
#import "CPTouchableView.h"
#import "CPSkill.h"
#import "UIImage+ImageBlur.h"
#import "NSData+Base64.h"

#define kActionSheetDeleteAccountTag 7911
#define kActionSheetChooseNewProfileImageTag 7912

@interface ProfileViewController () <CPTouchViewDelegate, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UIButton *profileImageButton;
@property (weak, nonatomic) IBOutlet UITextField *nicknameTextField;
@property (weak, nonatomic) IBOutlet UILabel *skillsLabel;
@property (weak, nonatomic) IBOutlet UILabel *categoriesLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UILabel *skillsTitle;
@property (weak, nonatomic) IBOutlet UILabel *visibilityLabel;
@property (weak, nonatomic) IBOutlet UIView *emailView;
@property (weak, nonatomic) IBOutlet UILabel *changePhotoLabel;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;

@property (strong, nonatomic) IBOutlet UILabel *emailValidationMsg;

@property (weak, nonatomic) IBOutlet UIView *profileHeaderView;
@property (weak, nonatomic) IBOutlet UIWebView *backgroundWebView;

@property (weak, nonatomic) IBOutlet CPTouchableView *skillsView;
@property (weak, nonatomic) IBOutlet CPTouchableView *visibilityView;
@property (weak, nonatomic) IBOutlet CPTouchableView *categoryView;
@property (weak, nonatomic) IBOutlet CPTouchableView *deleteTouchable;

@property (weak, nonatomic) IBOutlet UIView *detailsView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *floatView;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;

- (IBAction)gearPressed:(id)sender;
- (IBAction)chooseNewProfileImage:(id)sender;

@property (strong, nonatomic) User *currentUser;
@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) NSString *pendingEmail;

@property (strong, nonatomic) UIBarButtonItem *gearButton;

@property (assign, nonatomic) BOOL finishedSync;
@property (assign, nonatomic) BOOL newDataFromSync;

@property (strong, nonatomic, getter = cacheManager) NSCache *cache;
@end

@implementation ProfileViewController
@synthesize profileHeaderView = _profileHeaderView;
@synthesize backgroundWebView = _backgroundWebView;
@synthesize skillsLabel = _skillsLabel;
@synthesize categoriesLabel = _categoriesLabel;
@synthesize skillsView = _skillsView;
@synthesize visibilityView = _visibilityView;
@synthesize detailsView = _detailsView;
@synthesize categoryView = _categoryView;
@synthesize deleteTouchable = _deleteTouchable;
@synthesize scrollView = _scrollView;
@synthesize floatView = _floatView;
@synthesize arrowImageView = _arrowImageView;
@synthesize emailTextField = _emailTextField;
@synthesize skillsTitle = _skillsTitle;
@synthesize visibilityLabel = _visibilityLabel;
@synthesize emailView = _emailView;
@synthesize emailValidationMsg = _emailValidationMsg;
@synthesize profileImageButton = _profileImageButton;

@synthesize imagePicker = _imagePicker;
@synthesize currentUser = _currentUser;
@synthesize finishedSync = _finishedSync;
@synthesize newDataFromSync = _newDataFromSync;
@synthesize pendingEmail = _pendingEmail;
@synthesize nicknameTextField = _nicknameTextField;
@synthesize gearButton = _gearButton;
@synthesize changePhotoLabel = _changePhotoLabel;
@synthesize profileImageView = _profileImageView;
@synthesize cache = _cache;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// lazily instantiate image picker when we call the getter
- (UIImagePickerController *)imagePicker
{
    if (!_imagePicker) {
        _imagePicker = [[UIImagePickerController alloc] init];
    }
    return _imagePicker;
}

- (NSCache *)cacheManager
{
    if (!_cache) {
        _cache = [[NSCache alloc] init];
    }
    return _cache;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [SVProgressHUD show];
    
    self.gearButton = self.navigationItem.rightBarButtonItem;
    
    self.skillsView.delegate = self;
    self.visibilityView.delegate = self;
    self.categoryView.delegate = self;
    self.deleteTouchable.delegate = self;
    self.imagePicker.delegate = self;

    UIColor *paper = [UIColor colorWithPatternImage:[UIImage imageNamed:@"paper-texture.jpg"]];
    self.profileHeaderView.backgroundColor = paper;
    self.detailsView.backgroundColor = [paper colorWithAlphaComponent:0.8f];
    self.detailsView.frame = CGRectOffset(self.detailsView.frame, 0, 120);
    
    [CPUIHelper changeFontForTextField:self.nicknameTextField toLeagueGothicOfSize:30];
    [CPUIHelper changeFontForLabel:self.changePhotoLabel toLeagueGothicOfSize:20];

    [CPUIHelper setDefaultCorners:self.skillsView andAlpha:0.3];
    [CPUIHelper setDefaultCorners:self.categoryView andAlpha:0.3];
    [CPUIHelper setDefaultCorners:self.visibilityView andAlpha:0.3];
    [CPUIHelper setDefaultCorners:self.emailView andAlpha:0];

    [CPUIHelper setCorners:self.deleteTouchable
                withBorder:self.deleteTouchable.backgroundColor
                    Radius:8.0f
        andBackgroundColor:self.deleteTouchable.backgroundColor];

    self.scrollView.contentSize = CGSizeMake(320, 485);

    self.currentUser = [CPUserDefaultsHandler currentUser];
    [self placeCurrentUserDataAnimated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.finishedSync) {
        // show a loading HUD
        [SVProgressHUD showWithStatus:@"Loading..."];
        [self syncWithWebData];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    CGRect profileImageFrame = self.profileImageView.frame;
    profileImageFrame.origin.x = -100;
    self.profileImageView.frame = profileImageFrame;
}

- (void)viewDidUnload
{
    [self setBackgroundWebView:nil];
    [self setProfileHeaderView:nil];
    [self setSkillsLabel:nil];
    [self setSkillsView:nil];
    [self setDetailsView:nil];
    [self setCategoryView:nil];
    [self setDeleteTouchable:nil];
    [self setScrollView:nil];
    [self setEmailTextField:nil];
    [self setSkillsView:nil];
    [self setVisibilityView:nil];
    [self setEmailValidationMsg:nil];
    [self setProfileImageButton:nil];
    [self setCategoriesLabel:nil];
    [self setSkillsTitle:nil];
    [self setVisibilityLabel:nil];
    [self setFloatView:nil];
    [self setArrowImageView:nil];
    [self setEmailView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Web Data Sync

- (void)placeCurrentUserDataAnimated:(BOOL)animated
{
    
    UIImage *profilePhoto = [self.cache objectForKey:@"profilePhoto"];
    
    if (!profilePhoto) {    
        profilePhoto = [UIImage imageWithData:[NSData dataWithContentsOfURL:self.currentUser.photoURL]];    
    }
    
    [self.profileImageView setImage:profilePhoto];
    
    NSString *fullHTML = [self.cache objectForKey:@"fullHTML"];
    
    if (!fullHTML) {
        
        GRMustacheTemplate *template = [GRMustacheTemplate templateFromResource:@"ProfileBackground"
                                                                         bundle:nil
                                                                          error:NULL];
        
        UIImage *blurredImage = [profilePhoto imageWithGaussianBlur];
        NSData *imageData = UIImageJPEGRepresentation(blurredImage, 1.0);
        
        fullHTML = [template renderObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                           [imageData base64EncodedString],
                                           @"photo-string",
                                           nil]];
        if (profilePhoto) {
            [self.cache setObject:profilePhoto forKey:@"profilePhoto"];
            [self.cache setObject:fullHTML forKey:@"fullHTML"];
        }
    }
    
    [self.backgroundWebView loadHTMLString:fullHTML baseURL:nil];
    // put the nickname
    self.nicknameTextField.text = self.currentUser.nickname;

    if (self.currentUser.skills.count > 1) {
        self.skillsTitle.text = [NSString stringWithFormat:@"My %d strongest skills are ...", self.currentUser.skills.count];

        self.skillsLabel.text = @"";
        for (CPSkill *skill in self.currentUser.skills) {
            if (self.skillsLabel.text.length == 0) {
                self.skillsLabel.text = skill.name;
            } else {
                self.skillsLabel.text = [NSString stringWithFormat:@"%@, %@", self.skillsLabel.text, skill.name];
            }
        }
    } else {
        self.skillsTitle.text = @"My strongest skill is ...";

        if (self.currentUser.skills.count == 1) {
            CPSkill *skill = (CPSkill *)[self.currentUser.skills objectAtIndex:0];
            self.skillsLabel.text = skill.name;
        } else {
            self.skillsLabel.text = @"None";
        }
    }

    CGFloat expectedHeight = [CPUIHelper expectedHeightForLabel:self.skillsLabel];
    if (expectedHeight > 20) {
        self.arrowImageView.frame = CGRectMake(261, 7 + (expectedHeight - 20) / 2, 12, 18);
        self.floatView.frame = CGRectMake(0, 80 + expectedHeight - 20, 300, 265);
        self.detailsView.frame =  CGRectMake(10, 120, 300, 346 + expectedHeight - 20);
        self.skillsLabel.frame = CGRectMake(self.skillsLabel.frame.origin.x, self.skillsLabel.frame.origin.y, 250, expectedHeight);
        self.skillsView.frame = CGRectMake(self.skillsView.frame.origin.x, self.skillsView.frame.origin.y, 280, 32 + expectedHeight - 20);
    } else {
        self.arrowImageView.frame = CGRectMake(261, 7, 12, 18);
        self.floatView.frame = CGRectMake(0, 80, 300, 265);
        self.detailsView.frame =  CGRectMake(10, 120, 300, 346);
        self.skillsLabel.frame = CGRectMake(self.skillsLabel.frame.origin.x, self.skillsLabel.frame.origin.y, 250, 20);
        self.skillsView.frame = CGRectMake(self.skillsView.frame.origin.x, self.skillsView.frame.origin.y, 280, 32);
    }

    if ([self.currentUser.profileURLVisibility isEqualToString:@"global"]) {
        self.visibilityLabel.text = @"Publicly Visible";
    } else {
        self.visibilityLabel.text = @"Only people logged in";
    }

    if (!self.pendingEmail) {
        // there's no pending email so put whatever the current email is
        self.emailTextField.text = self.currentUser.email;
    } else {
        // there's a pending email so show that to the user so they know it took
        self.emailTextField.text = self.pendingEmail;
    }
    //Enable ValueChanged tracking for the emailTextField
    [_emailTextField addTarget:self action:@selector(emailTextField_ValueChanged:) forControlEvents:UIControlEventEditingChanged];
    //This validates the current email address.  Should be valid, but just in case.
    [self emailTextField_ValueChanged:_emailTextField];

    
    if ([self.currentUser.majorJobCategory isEqualToString:self.currentUser.minorJobCategory]) {
        [self.categoriesLabel setText:[self.currentUser.majorJobCategory capitalizedString]];
    } else {
        [self.categoriesLabel setText:[NSString stringWithFormat:@"%@, %@", [self.currentUser.majorJobCategory capitalizedString], [self.currentUser.minorJobCategory capitalizedString]]];
    }

    if (animated) {
        [UIView animateWithDuration:0.3f
                              delay:1.0f
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             CGRect profileImageFrame = self.profileImageView.frame;
                             profileImageFrame.origin.x = 0;
                             self.profileImageView.frame = profileImageFrame;
                         }
                         completion:nil];
    }
}

- (void)syncWithWebData
{
    User *webSyncUser = [[User alloc] init];

    // load the user's data from the web by their id
    webSyncUser.userID = self.currentUser.userID;
    [SVProgressHUD show];

    // TODO: Let's not load all of the user resume data here, just what can be changed
    [webSyncUser loadUserResumeData:^(NSError *error) {
        if (!error) {
            // TODO: make this a better solution by checking for a problem with the PHP session cookie in CPApi
            // for now if the email comes back null this person isn't logged in so we're going to send them to do that.
            if ([webSyncUser.email isKindOfClass:[NSNull class]] || [webSyncUser.email length] == 0) {
                [self dismissModalViewControllerAnimated:YES];
                NSString *message = @"There was a problem getting your data!\nPlease logout and login again.";
                [SVProgressHUD dismissWithError:message afterDelay:kDefaultDismissDelay];
            } else {
                // let's update the local current user with any new data

                if (![self.currentUser.nickname isEqualToString:webSyncUser.nickname]) {
                    self.currentUser.nickname = webSyncUser.nickname;
                    self.newDataFromSync = YES;
                }

                // check email
                if (![self.currentUser.email isEqualToString:webSyncUser.email]) {
                    self.currentUser.email = webSyncUser.email;
                    self.newDataFromSync = YES;
                }

                // check photo url
                if (![self.currentUser.photoURLString isEqual:webSyncUser.photoURLString]) {
                    self.currentUser.photoURLString = webSyncUser.photoURLString;
                    self.newDataFromSync = YES;
                }

                if (![self.currentUser.joinDate isEqual:webSyncUser.joinDate]) {
                    self.currentUser.joinDate = webSyncUser.joinDate;
                    self.newDataFromSync = YES;
                }

                if (self.currentUser.enteredInviteCode != webSyncUser.enteredInviteCode) {
                    self.currentUser.enteredInviteCode = webSyncUser.enteredInviteCode;
                    self.newDataFromSync = YES;
                }

                if (self.currentUser.majorJobCategory != webSyncUser.majorJobCategory) {
                    self.currentUser.majorJobCategory = webSyncUser.majorJobCategory;
                    self.newDataFromSync = YES;
                }

                if (self.currentUser.minorJobCategory != webSyncUser.minorJobCategory) {
                    self.currentUser.minorJobCategory = webSyncUser.minorJobCategory;
                    self.newDataFromSync = YES;
                }

                if (![self.currentUser.hourlyRate isEqualToString:webSyncUser.hourlyRate]) {
                    self.currentUser.hourlyRate = webSyncUser.hourlyRate;
                    self.newDataFromSync = YES;
                }

                if (![self.currentUser.skills isEqualToArray:webSyncUser.skills]) {
                    self.currentUser.skills = webSyncUser.skills;
                    self.newDataFromSync = YES;
                }

                if (![self.currentUser.profileURLVisibility isEqualToString:webSyncUser.profileURLVisibility]) {
                    self.currentUser.profileURLVisibility = webSyncUser.profileURLVisibility;
                    self.newDataFromSync = YES;
                }

                if (self.newDataFromSync) {
                    [CPUserDefaultsHandler setCurrentUser:self.currentUser];
                    [self placeCurrentUserDataAnimated:YES];
                }
                
                [SVProgressHUD dismiss];
                self.newDataFromSync = NO;
                self.finishedSync = YES;
            }
        } else {
            [self dismissModalViewControllerAnimated:YES];
            NSString *message = @"There was a problem getting current data. Please try again in a little while.";
            [SVProgressHUD showErrorWithStatus:message duration:kDefaultDismissDelay];
        }
    }];
}


#pragma mark - Image Picker Controller Delegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissModalViewControllerAnimated:YES];
    [self placeCurrentUserDataAnimated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker
       didFinishPickingImage:(UIImage *)image
                 editingInfo:(NSDictionary *)editingInfo
{
    [self.cache removeAllObjects];
    // get rid of the image picker
    [picker dismissModalViewControllerAnimated:YES];
    [SVProgressHUD showWithStatus:@"Uploading photo"];
    // upload the image
    [CPapi uploadUserProfilePhoto:image withCompletion:^(NSDictionary *json, NSError *error) {
        if ([[json objectForKey:@"succeeded"] boolValue]) {
            // response was success ... we uploaded a new profile picture
            [self updateCurrentUserWithNewData:json];
            [SVProgressHUD dismiss];
        } else {
#if DEBUG
            NSLog(@"Error while uploading file. Here's the json: %@", json);
#endif
            NSString *message = [json objectForKey:@"message"];
            if ([message isKindOfClass:[NSNull class]]) {
                // blank message from server
                message = @"There was an problem uploading your image.\n Please try again.";
            }

            [SVProgressHUD dismissWithError:message afterDelay:kDefaultDismissDelay];
        }
    }];
}


#pragma mark - User Updating

- (void)updateCurrentUserWithNewData:(NSDictionary *)json
{
    BOOL animated = NO;

    NSDictionary *paramsDict = [json objectForKey:@"params"];
    if (paramsDict) {
        // update the current user in NSUserDefaults with the change
        NSString *newNickname = [paramsDict objectForKey:@"new_nickname"];
        if (newNickname) {
            self.currentUser.nickname = newNickname;
        }

        NSString *pendingEmail = [paramsDict objectForKey:@"pending_email"];
        if (pendingEmail) {
            // user wants to change email, set our pending email instance variable to that
            self.pendingEmail = pendingEmail;
            [SVProgressHUD showSuccessWithStatus:[json objectForKey:@"message"] duration:kDefaultDismissDelay];
        }
        // update the user's photo url
        NSString *newPhoto = [paramsDict objectForKey:@"picture"];
        if (newPhoto) {
            self.currentUser.photoURLString = [paramsDict objectForKey:@"picture"];
            animated = YES;
        }

        // store the updated user in NSUserDefaults
        [CPUserDefaultsHandler setCurrentUser:self.currentUser];
    }
    [self placeCurrentUserDataAnimated:animated];
}

#pragma mark - Email Text Field Validation
- (void)emailTextField_ValueChanged:(id)sender {
    UITextField *tf = (UITextField *)sender;

    if(tf.text.length == 0 || ![CPUtils validateEmailWithString:tf.text]) {
        self.emailValidationMsg.text = @"Must be a valid email address!";
    }else {
        self.emailValidationMsg.text = @"";
    }
}


#pragma mark - Action Sheet Delegate

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (kActionSheetChooseNewProfileImageTag == actionSheet.tag) {
        if (buttonIndex == 0 || buttonIndex == 1) {
            if (buttonIndex == 0) {
                // user wants to pick from camera
                self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                // use the front camera by default (if we have one)
                // if there's no front camera we'll use the back (3GS)
                if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerCameraDeviceFront]) {
                    self.imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
                }

            } else if (buttonIndex == 1) {
                // user wants to pick from photo library
                self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            }
            // show the image picker
            [self presentModalViewController:self.imagePicker animated:YES];
        }
    } else if (kActionSheetDeleteAccountTag == actionSheet.tag) {
        if (actionSheet.destructiveButtonIndex == buttonIndex) {
            [SVProgressHUD showWithStatus:@"Loading..."];

            [CPapi deleteAccountWithParameters:nil
                                    completion:
                                            ^(NSDictionary *json, NSError *error) {
                                                if (error) {
                                                    [SVProgressHUD dismissWithError:[error localizedDescription]
                                                            afterDelay:kDefaultDismissDelay];
                                                    return;
                                                }

                                                if (NO == [[json objectForKey:@"succeeded"] boolValue]) {
                                                    [SVProgressHUD dismissWithError:[json objectForKey:@"message"]
                                                            afterDelay:kDefaultDismissDelay];
                                                    return;
                                                }

                                                [CPAppDelegate logoutEverything];

                                                SettingsMenuController *presentingViewController = (SettingsMenuController *)self.presentingViewController;
                                                if (presentingViewController.isMenuShowing) {
                                                    [presentingViewController showMenu:NO];
                                                }

                                                [self dismissModalViewControllerAnimated:NO];

                                                [CPAppDelegate showSignupModalFromViewController:presentingViewController
                                                                                        animated:YES];

                                                [SVProgressHUD dismissWithSuccess:[json objectForKey:@"message"]];
                                            }];
        }
    }
}


-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == self.emailTextField) {
        self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 250, 0);
        [self.scrollView setContentOffset: CGPointMake(0, 250) animated:YES];
    }

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
                                                                                           target:self 
                                                                                           action:@selector(cancelTextEntry:)];
    return YES;
}

- (void)cancelTextEntry:(id)sender
{
    [UIView animateWithDuration:0.3f animations:^{
        self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }];
    [self.nicknameTextField setText:self.currentUser.nickname];
    [self.emailTextField setText:self.currentUser.email];
    
    [self.nicknameTextField becomeFirstResponder];
    [self.nicknameTextField resignFirstResponder];

    self.navigationItem.rightBarButtonItem = self.gearButton;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    //Check for valid email address if textField is emailTextField
    if (textField == self.emailTextField &&
            (textField.text.length == 0  || ![CPUtils validateEmailWithString:textField.text])) {
        NSString *message = @"Email address does not appear to be valid.";
        // we had an error, let's tell the user and leave
        [SVProgressHUD showErrorWithStatus:message duration:kDefaultDismissDelay];
        return NO;
    }
    if (textField == self.emailTextField && [self.emailTextField.text isEqualToString:self.currentUser.email]) {
        [self cancelTextEntry:nil];
        return YES;
    }
    
    if (textField == self.nicknameTextField && [self.nicknameTextField.text isEqualToString:self.currentUser.nickname]) {
        [self cancelTextEntry:nil];
        return YES;
    }
    
    self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.navigationItem.rightBarButtonItem = self.gearButton;
    
    [SVProgressHUD show];
    [textField resignFirstResponder];

    // disable user interaction with the keyboard
    textField.userInteractionEnabled = NO;

    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:nil];

    if (textField == self.nicknameTextField) {
        // this is the nickname text field
        [params setObject:textField.text forKey:@"nickname"];
    } else if (textField == self.emailTextField) {
        [params setObject:textField.text forKey:@"email"];
    }

    [CPapi setUserProfileDataWithDictionary:params andCompletion:^(NSDictionary *json, NSError *error) {
        [SVProgressHUD dismiss];
        if (!error) {
            // let's see if there was a successful change
            if ([[json objectForKey:@"succeeded"] boolValue]) {
                textField.userInteractionEnabled = YES;
                [self updateCurrentUserWithNewData:json];
            } else {
                [SVProgressHUD showErrorWithStatus:[json objectForKey:@"message"] duration:kDefaultDismissDelay];
                [self updateCurrentUserWithNewData:nil];
            }
            textField.userInteractionEnabled = YES;
        } else {
            // error parsing JSON
        }
    }];
    
    return YES;
}

#pragma mark - IBActions

-(IBAction)gearPressed:(id)sender
{
    [self dismissPushModalViewControllerFromLeftSegue];
}

-(IBAction)chooseNewProfileImage:(id)sender
{
    UIActionSheet *cameraSheet = [[UIActionSheet alloc] initWithTitle:@"Image Source" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Camera", @"Photo Library", nil];
    cameraSheet.tag = kActionSheetChooseNewProfileImageTag;
    [cameraSheet showInView:self.view];
}

- (void)touchUp:(id)sender
{
    self.finishedSync = NO;
    if (sender == self.skillsView) {
        [self performSegueWithIdentifier:@"ProfileToSkillsSegue" sender:self];
    }
    
    if (sender == self.categoryView) {
        [self performSegueWithIdentifier:@"ProfileToJobCategoriesSegue" sender:self];
    }
    
    if (sender == self.visibilityView) {
        [self performSegueWithIdentifier:@"ProfileToVisibilitySegue" sender:self];
    }

    if (sender == self.deleteTouchable) {

        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Once you delete your account you can't get it back!"
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:@"Delete Account"
                                                        otherButtonTitles:nil];
        actionSheet.tag = kActionSheetDeleteAccountTag;
        [actionSheet showInView:self.view];
    }
}

@end
