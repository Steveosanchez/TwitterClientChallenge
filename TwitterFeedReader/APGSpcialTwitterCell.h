//
//  APGSpcialTwitterCell.h
//  dodgy
//
//  Created by Steve_Sanchez on 9/8/12.
//  Copyright (c) 2012 Apargo. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol APGSpecialTwitterCellDelegate;

@class Tweet;
@interface APGSpcialTwitterCell : UITableViewCell
@property (weak, nonatomic) id<APGSpecialTwitterCellDelegate> cellDelegate;
@property (weak, nonatomic) IBOutlet UIButton *replyButton;
@property (weak, nonatomic) IBOutlet UIButton *retweetButton;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;
@property (strong, nonatomic) Tweet *localTweet;
@end

@protocol APGSpecialTwitterCellDelegate <NSObject>

- (void)didSwiptToTheRight:(UITableViewCell *)gesture;
- (void)didSelectReply:(UITableViewCell *)tweet;

@end
