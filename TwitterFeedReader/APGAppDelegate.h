//
//  APGAppDelegate.h
//  TwitterFeedReader
//
//  Created by Steve_Sanchez on 5/5/13.
//  Copyright (c) 2013 ApargoLLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface APGAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (NSString *)documentsPath;
- (NSString *)cachePath;

+ (APGAppDelegate *)appDelegate;

@end
