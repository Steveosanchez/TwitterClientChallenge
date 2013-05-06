//
//  APGTwitterCell.h
//  TwitterFeedReader
//
//  Created by Steve_Sanchez on 5/5/13.
//  Copyright (c) 2013 ApargoLLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "APGCoreTextTweetView.h"
@protocol APGCommonTwitterCellDelegate;

@class Image, Tweet;

@interface APGTwitterCell : UITableViewCell<UIGestureRecognizerDelegate, APGCoreTextTweetViewDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UILabel *profileName;
@property (strong, nonatomic) Tweet *tweetObject;
@property (weak, nonatomic) IBOutlet UILabel *timeInterval;
@property (weak, nonatomic) id<APGCommonTwitterCellDelegate> localDelegate;
@property (weak, nonatomic) IBOutlet APGCoreTextTweetView *adjustedText;

- (void)addDate:(NSDate *)addedDate;
@end


@protocol APGCommonTwitterCellDelegate <NSObject>

- (void)didSwipeToTheLeft:(UITableViewCell *)cell;
- (void)didSelectURL:(UITableViewCell *)cell;

@end