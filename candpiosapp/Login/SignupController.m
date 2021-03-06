//
//  SignupController.m
//  candpiosapp
//
//  Created by David Mojdehi on 1/11/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "SignupController.h"
#import "FlurryAnalytics.h"
#import "UIViewController+isModal.h"

@interface SignupController ()
@end

@implementation SignupController
@synthesize linkedinLoginButton;
@synthesize dismissButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    [CPUIHelper makeButtonCPButton:self.dismissButton
                 withCPButtonColor:CPButtonGrey];
    [FlurryAnalytics logEvent:@"signupScreen"];
    
    // if this is being presented inside the app from the UITabBarController
    // then don't show the later button
    if (!self.isModal) {
        [self.dismissButton removeFromSuperview];
        
        // if the user is currently on the 4th tab
        // then bring them to the map once they login
        [CPAppDelegate settingsMenuController].afterLoginAction = CPAfterLoginActionShowMap;
    }
}

- (void)viewDidUnload
{
    [self setLinkedinLoginButton:nil];
    [self setDismissButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationItem setHidesBackButton:YES animated:NO];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    self.title = @"Log In";
    // Set the back button that will appear in pushed views
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" 
                                                                             style:UIBarButtonItemStyleDone 
                                                                            target:nil 
                                                                            action:nil];
    // prepare for the icons to fade in
    self.linkedinLoginButton.alpha = 0.0;
}

- (void) viewDidAppear:(BOOL)animated {
    // fade in the icons to direct user attention at them
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:0.3];
    self.linkedinLoginButton.alpha = 1.0;
    [UIView commitAnimations];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)loginWithLinkedInTapped:(id)sender 
{
	// Handle LinkedIn login
	// The LinkedIn login object will handle the sequence that follows
    [self performSegueWithIdentifier:@"ShowLinkedInLoginController" sender:sender];
    [FlurryAnalytics logEvent:@"startedLinkedInLogin"];
}

- (IBAction) dismissClick:(id)sender
{
    // make sure the selected index is 1 so it goes to the map
    [CPAppDelegate tabBarController].selectedIndex = 1;
    [self dismissModalViewControllerAnimated:YES];
    [FlurryAnalytics logEvent:@"skippedSignup"];
}

@end
