//
//  UserSettingsViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 3/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UserSettingsTableViewController.h"
#import "CPapi.h"
#import "User.h"
#import "SVProgressHUD.h"

@interface UserSettingsTableViewController () <UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

-(void)syncWithWebData;

@end

@implementation UserSettingsTableViewController
@synthesize nicknameTextField = _nicknameTextField;
@synthesize emailTextField = _emailTextField;
@synthesize pendingEmail = _pendingEmail;
@synthesize currentUser = _currentUser;
@synthesize imagePicker = _imagePicker;
@synthesize finishedSync = _finishedSync;
@synthesize newDataFromSync = _newDataFromSync;
@synthesize profileImageButton = _profileImageButton;
@synthesize profileImage = _profileImage;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
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

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.tableView.separatorColor = [UIColor colorWithRed:(68/255.0) green:(68/255.0) blue:(68/255.0) alpha:1.0];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // be the delegate of the image picker
    self.imagePicker.delegate = self;
    
    // set our current user to the user in NSUserDefaults
    self.currentUser = [CPAppDelegate currentUser];
    
    // add an imageview to the profileImageButton
    self.profileImage = [[UIImageView alloc] initWithFrame:CGRectMake(1, 1, 31, 31)];
    
    // add the profile image imageview to the button
    [self.profileImageButton addSubview:self.profileImage];
    
    // put the local data on the card so it's there when it spins around
    [self placeCurrentUserData];
    // sync local data with data from web
    [self syncWithWebData];
}

- (void)viewDidUnload
{
    [self setNicknameTextField:nil];
    [self setEmailTextField:nil];
    [self setProfileImageButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.finishedSync) {
        // show a loading HUD
        [SVProgressHUD showWithStatus:@"Loading..."];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Web Data Sync

- (void)placeCurrentUserData
{
    // put the nickname
    self.nicknameTextField.text = self.currentUser.nickname;
    
    if (!self.pendingEmail) {
        // there's no pending email so put whatever the current email is
        self.emailTextField.text = self.currentUser.email;
    } else {
        // there's a pending email so show that to the user so they know it took
        self.emailTextField.text = self.pendingEmail;
    }
    
    // seems like this should use the thumbnail but the frame is 31x31 so retina display wants at least 62x62
    [self.profileImage setImageWithURL:self.currentUser.urlPhoto placeholderImage:[UIImage imageNamed:@"texture-diagonal-noise-dark"]]; 
    
}

- (void)syncWithWebData
{
    User *webSyncUser = [[User alloc] init];
    
    // load the user's data from the web by their id
    webSyncUser.userID = self.currentUser.userID;
   
    [webSyncUser loadUserResumeData:^(NSError *error) {
        if (!error) {
            // let's update the local current user with any new data
            
            // check nickname
            if (![self.currentUser.nickname isEqualToString:webSyncUser.nickname]) {
                self.currentUser.nickname = webSyncUser.nickname;
                self.newDataFromSync = YES;
            }
            
            // check photo url
            if (![self.currentUser.urlPhoto isEqual:webSyncUser.urlPhoto]) {
                self.currentUser.urlPhoto = webSyncUser.urlPhoto;
                self.newDataFromSync = YES;
            }
            
            // check email
            if (![self.currentUser.email isEqualToString:webSyncUser.email]) {
                self.currentUser.email = webSyncUser.email;
                self.newDataFromSync = YES;
            }
            
            // if the sync brought us new data
            if (self.newDataFromSync) {
                // save the changes to the local current user
                [CPAppDelegate saveCurrentUserToUserDefaults:self.currentUser]; 
            }
            
            // reset the newDataFromSync boolean
            self.newDataFromSync = NO;
            
            // we finshed our sync so set that boolean
            self.finishedSync = YES;
            // kill the hud if there is one
            [SVProgressHUD dismiss];    
            
            // place the current user data into the table
            [self placeCurrentUserData];
        } else {
            NSString *message = @"There was a problem getting current data.\nPlease try again in a little while";
            // we had an error, let's tell the user and leave
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                                message:message
                                                               delegate:self 
                                                      cancelButtonTitle:@"OK" 
                                                      otherButtonTitles:nil];
            // give this alertView a tag so we can recognize this alertview in the
            // delegate function
            alertView.tag = 7879;
            [alertView show];            
        }      
    }];
    
}

#pragma mark - User Updating

- (void)updateCurrentUserWithNewData:(NSDictionary *)json
{
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
            
            // show an alert if the update was to the user email so they know they have to confirm
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Email Change" 
                                                                message:[json objectForKey:@"message"]
                                                               delegate:self 
                                                      cancelButtonTitle:@"OK" 
                                                      otherButtonTitles:nil];
            [alertView show];
        }
        NSURL *newPhoto = [paramsDict objectForKey:@"picture"];
        if (newPhoto) {
            // we have a new profile picture
            // update the user's photo url
            self.currentUser.urlPhoto = newPhoto;
        }
        
        // store the updated user in NSUserDefaults
        [CPAppDelegate saveCurrentUserToUserDefaults:self.currentUser];
    }
    // if we don't get passed a responseDict
    // there's nothing to update so we're just putting back the old
    [self placeCurrentUserData];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

#pragma mark - UITextField delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // alloc-init a spinner
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    
    // set the frame of the spinner so it's vertically centered on the right side of the row
    CGRect spinFrame = spinner.frame;
    spinFrame.origin.x = textField.superview.frame.size.width - 10 - spinFrame.size.width;
    spinFrame.origin.y = (textField.superview.frame.size.height / 2) - (spinFrame.size.height / 2) ;
    spinner.frame = spinFrame;
    [textField.superview addSubview:spinner];

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
    
    // clear the text field so we can show the spinner
    textField.text = @"";
    // spin the spinner and drop the keyboard
    [spinner startAnimating];
    
    [CPapi setUserProfileDataWithDictionary:params andCompletion:^(NSDictionary *json, NSError *error) {
        if (!error) {
            // let's see if there was a successful change
            if ([[json objectForKey:@"succeeded"] boolValue]) {
                [spinner stopAnimating];
                textField.userInteractionEnabled = YES;
                
                [self updateCurrentUserWithNewData:json];
            } else {
                // show the user the error message
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Uh Oh!" 
                                                                    message:[json objectForKey:@"message"]
                                                                   delegate:self 
                                                          cancelButtonTitle:@"OK" 
                                                          otherButtonTitles:nil];
                [alertView show];
                
                [self updateCurrentUserWithNewData:nil];
            }
            [spinner stopAnimating];
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
    [self dismissModalViewControllerAnimated:YES];
}

-(IBAction)chooseNewProfileImage:(id)sender
{
    UIActionSheet *cameraSheet = [[UIActionSheet alloc] initWithTitle:@"Image Source" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Camera", @"Photo Library", nil];
    [cameraSheet showInView:self.view];
}

#pragma mark - Action Sheet Delegate

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0 || buttonIndex == 1) {
        if (buttonIndex == 0) {
            // user wants to pick from camera
            self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            // use the front camera by default
            self.imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        } else if (buttonIndex == 1) {
            // user wants to pick from photo library
            self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        // show the image picker
        [self presentModalViewController:self.imagePicker animated:YES];
    }    
}

#pragma mark - Image Picker Controller Delegate

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    // get rid of the image picker
    [picker dismissModalViewControllerAnimated:YES];
    
    // upload the image
    [CPapi uploadUserProfilePhoto:image withCompletion:^(NSDictionary *json, NSError *error) {
        if ([[json objectForKey:@"succeeded"] boolValue]) {
            // response was success ... we uploaded a new profile picture
            [self updateCurrentUserWithNewData:json];
        } else {
            // show the user the error message
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Uh Oh!" 
                                                                message:[json objectForKey:@"message"]
                                                               delegate:self 
                                                      cancelButtonTitle:@"OK" 
                                                      otherButtonTitles:nil];
            [alertView show];
        }
    }];
}

#pragma mark - Alert View Delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // dismiss the modal view controller if there was an error syncing the user data
    if (alertView.tag == 7879) {
        [self dismissModalViewControllerAnimated:YES];
    }
}

@end
