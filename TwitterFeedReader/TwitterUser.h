//
//  TwitterUser.h
//  TwitterFeedReader
//
//  Created by Steve_Sanchez on 5/5/13.
//  Copyright (c) 2013 ApargoLLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Tweet, Geo, Image;

@interface TwitterUser : NSManagedObject

@property (nonatomic, retain) NSString * userName;
@property (nonatomic, retain) NSNumber * userID;
@property (nonatomic, retain) NSString * userRealName;
@property (nonatomic, retain) Tweet *tweet;
@property (nonatomic, strong) Image *profileImage;
@property (nonatomic, strong) NSString *location;
@end
