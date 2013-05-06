//
//  Tweet.h
//  TwitterFeedReader
//
//  Created by Steve_Sanchez on 5/5/13.
//  Copyright (c) 2013 ApargoLLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Image, TwitterUser, Geo;

@interface Tweet : NSManagedObject

@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSString * linkedURL;
@property (nonatomic, retain) NSString * tweetId;
@property (nonatomic, retain) NSNumber * userID;
@property (nonatomic, retain) NSNumber * favorited;
@property (nonatomic, retain) id urls;
@property (nonatomic, retain) id hastags;
@property (nonatomic, retain) NSString * placeName;
@property (nonatomic, retain) NSString * countryCode;
@property (nonatomic, retain) NSNumber * retweeted;
@property (nonatomic, retain) Image *profileImage;
@property (nonatomic, retain) Image *tweetImage;
@property (nonatomic, retain) TwitterUser *user;
@property (nonatomic, retain) Geo *geo;

- (void)buildNewTweetWithAttributes:(NSDictionary *)attributes;
- (void)updateWithAttributes:(NSDictionary *)attributes;
@end
