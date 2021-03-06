//
//  UserProfileViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#define kRequestToAddToMyContactsActionSheetTitle @"Request to exchange contact info?"

@interface UserProfileViewController : UIViewController

@property (nonatomic, strong) User *user;
@property (assign, nonatomic) BOOL isF2FInvite;

- (IBAction)f2fInvite;
- (void)placeUserDataOnProfile;

@end
