//
//  APGCoreTextTweetView.h
//  dodgy
//
//  Created by Steve_Sanchez on 9/13/12.
//  Copyright (c) 2012 Apargo. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol APGCoreTextTweetViewDelegate;


@interface APGCoreTextTweetView : UIView

@property (strong, nonatomic) id coreTextDrawDelegate;
@property (strong, nonatomic) NSString *tweetText;
@property (weak, nonatomic) id <APGCoreTextTweetViewDelegate> localDelegate;
- (void)drawIntoLayer:(CALayer *)layer inContext:(CGContextRef)ctx;
@end


@protocol APGCoreTextTweetViewDelegate <NSObject>

- (void)didSelectView;

@end