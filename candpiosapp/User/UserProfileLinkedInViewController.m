//
//  UserProfileLinkedInViewController.m
//  candpiosapp
//
//  Created by Bryan Galusha on 5/8/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UserProfileLinkedInViewController.h"

@interface UserProfileLinkedInViewController ()


@end

@implementation UserProfileLinkedInViewController
@synthesize linkedInProfileUrlAddress = _linkedInProfileUrlAddress;
@synthesize socialWebView = _socialWebView;

- (id)initWithNibName:(NSString *)nibNameOrNil  bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.socialWebView.delegate = self;
    self.socialWebView.hidden = YES;
    
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    //Create a URL object.
    NSURL *url = [NSURL URLWithString:self.linkedInProfileUrlAddress];
    
    //URL Requst Object
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    
    //Load the request in the UIWebView.
    [self.socialWebView loadRequest:requestObj]; 
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    [self setSocialWebView:nil];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UIWebViewDelegate


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.socialWebView.hidden = NO;
    [SVProgressHUD dismiss];
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [SVProgressHUD dismissWithError:[error localizedDescription]
                         afterDelay:kDefaultDismissDelay];
}

@end
