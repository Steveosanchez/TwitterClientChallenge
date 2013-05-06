//
//  APGTwitterCell.m
//  TwitterFeedReader
//
//  Created by Steve_Sanchez on 5/5/13.
//  Copyright (c) 2013 ApargoLLC. All rights reserved.
//

#import "APGTwitterCell.h"
#import "NSDate+NSDate_Extensions.h"
#import "APGCoreTextTweetView.h"
#import "Tweet.h"
#import "Image.h"
#import "TwitterUser.h"


@implementation APGTwitterCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self addObserver:self forKeyPath:@"tweetObject.user.profileImage.thumbnailImage" options:0 context:&self->_profileImage];
        UISwipeGestureRecognizer *swipeGest = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(processSwipe:)];
        swipeGest.direction = UISwipeGestureRecognizerDirectionLeft;
        [self addGestureRecognizer:swipeGest];
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)addDate:(NSDate *)addedDate{
    NSDictionary *intervalDict = [[NSDate date] timeIntervalForDate:addedDate];
    
    NSNumber *timeInt = [intervalDict valueForKey:@"TimeInterval"];
    NSNumber *timeValue = [intervalDict valueForKey:@"TimeValue"];
    
    NSMutableString *timeIntervalString = [NSMutableString string];
    NSString *timeValueString = [NSString stringWithFormat:@"%d", timeValue.integerValue];
    
    switch (timeInt.integerValue) {
        case kTimeIntervalMonths:{
            [timeIntervalString appendString:@"month"];
            break;
        }
        case kTimeIntervalWeeks:{
            [timeIntervalString appendString:@"wks"];
            break;
        }
        case kTimeIntervalDays:{
            [timeIntervalString appendString:@"days"];
            break;
        }
        case kTimeIntervalHours:{
            [timeIntervalString appendString:@"hrs"];
            break;
        }
        case kTimeIntervalMinutes:{
            [timeIntervalString appendString:@"min"];
            break;
        }
        case kTimeIntervalSeconds:{
            [timeIntervalString appendString:@"sec"];
            break;
        }
            
        default:
            break;
    }
    
    NSString *completeTimeString = [NSString stringWithFormat:@"• %@ %@", timeValueString, timeIntervalString];
    
    self.timeInterval.text = nil;
    self.timeInterval.text = completeTimeString;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if (context == &self->_profileImage) {
        if ([keyPath isEqualToString:@"tweetObject.user.profileImage.thumbnailImage"]) {
            if ([[[NSRunLoop currentRunLoop] currentMode] isEqual:NSDefaultRunLoopMode]) {
                self.profileImage.image = self.tweetObject.user.profileImage.thumbnailImage;
            }else{
                [self performSelector:@selector(addImageOnRunLoop:) withObject:self.tweetObject.user.profileImage.thumbnailImage afterDelay:0.0f inModes:@[NSDefaultRunLoopMode]];
            }
        }
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)addImageOnRunLoop:(UIImage *)image{
    self.profileImage.image = image;
}
- (void)setTweetObject:(Tweet *)tweetObject{
    self->_tweetObject = tweetObject;
    self.profileName.text = self.tweetObject.user.userRealName;
    self.adjustedText.tweetText = self.tweetObject.body;
    self.profileImage.image = self->_tweetObject.user.profileImage.thumbnailImage;
    [self addDate:self.tweetObject.dateCreated];
    
}

- (void)processSwipe:(UISwipeGestureRecognizer *)gesture{
    if ([self.localDelegate respondsToSelector:@selector(didSwipeToTheLeft:)]) {
        [self.localDelegate didSwipeToTheLeft:(UITableViewCell*)gesture.view];
    }
}

- (void)didSelectView{
    [self.localDelegate didSelectURL:self];
}

- (void)didTransitionToState:(UITableViewCellStateMask)state{
    CALayer *theLayer = [CALayer layer];
	theLayer.contentsScale = [[UIScreen mainScreen] scale];
	
	CGRect bounds = [self.adjustedText bounds];
	theLayer.position = CGPointMake(bounds.size.width/2, bounds.size.height/2);
	
	theLayer.bounds = bounds;
	theLayer.backgroundColor = [[UIColor  clearColor] CGColor];
    [theLayer setDelegate:self.adjustedText.coreTextDrawDelegate];
    
    CALayer* viewLayer = [self.adjustedText layer];
    NSArray* subLayers = [viewLayer sublayers];
        // Remove any previous CALayer
    for (CALayer* aSubLayer in subLayers) {
        [aSubLayer removeFromSuperlayer];
    }
    
    [[self.adjustedText layer] addSublayer:theLayer];
    [self.adjustedText setNeedsDisplay];
    [theLayer setNeedsDisplay];
    [theLayer display];
}

/*- (void)setFrame:(CGRect)frame{
    CALayer *theLayer = [CALayer layer];
	theLayer.contentsScale = [[UIScreen mainScreen] scale];
	
	CGRect bounds = [self.adjustedText bounds];
	theLayer.position = CGPointMake(bounds.size.width/2, bounds.size.height/2);
	
	theLayer.bounds = bounds;
	theLayer.backgroundColor = [[UIColor  clearColor] CGColor];
    [theLayer setDelegate:self.adjustedText.coreTextDrawDelegate];
    
    CALayer* viewLayer = [self.adjustedText layer];
    NSArray* subLayers = [viewLayer sublayers];
        // Remove any previous CALayer
    for (CALayer* aSubLayer in subLayers) {
        [aSubLayer removeFromSuperlayer];
    }
    
    [[self.adjustedText layer] addSublayer:theLayer];
    [self.adjustedText setNeedsDisplay];
    [theLayer setNeedsDisplay];
    [theLayer display];
}*/

- (void)dealloc{
    [self removeObserver:self forKeyPath:@"tweetObject.user.profileImage.thumbnailImage" context:&self->_profileImage];
}
@end
