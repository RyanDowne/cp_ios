//
//  PostBaseCell.h
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CPUserActionCell.h"
#import "CPPost.h"

@interface PostBaseCell : CPUserActionCell

@property (nonatomic, assign) IBOutlet UIButton *senderProfileButton;
@property (nonatomic, assign) IBOutlet UILabel *entryLabel;
@property (nonatomic, strong) CPPost* post;
@property (nonatomic, strong) UIButton *plusButton;
@property (nonatomic, strong) UILabel *likeCountLabel;
@property (nonatomic, strong) UIImageView *likeCountBubble;

- (void) addPlusWidget;
- (void) changeLikeCountToValue:(int)value animated:(BOOL)animated;

@end
