//
//  Tweet.m
//  TwitterFeedReader
//
//  Created by Steve_Sanchez on 5/5/13.
//  Copyright (c) 2013 ApargoLLC. All rights reserved.
//

#import "Tweet.h"
#import "Image.h"
#import "TwitterUser.h"
#import "Geo.h"
@implementation Tweet

@dynamic body;
@dynamic dateCreated;
@dynamic linkedURL;
@dynamic tweetId;
@dynamic userID;
@dynamic favorited;
@dynamic urls;
@dynamic hastags;
@dynamic placeName;
@dynamic countryCode;
@dynamic retweeted;
@dynamic profileImage;
@dynamic tweetImage;
@dynamic user;
@dynamic geo;


- (void)buildNewTweetWithAttributes:(NSDictionary *)attributes{
    self.body = attributes[kTwitterKeyValueText];
    NSString *stringDate = [attributes objectForKey:kTwitterKeyValueCreatedOnDate];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"EEE MMM dd HH:mm:ss ZZZZ yyyy"];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    NSDate *uploadDate = nil;
    NSRange range = NSMakeRange(0, [stringDate length]);
    NSError *dateError = nil;
    [formatter getObjectValue:&uploadDate forString:stringDate range:&range error:&dateError];
    
    self.dateCreated = uploadDate;
    self.tweetId = attributes[kTwitterKeyValueTweetIdString];
    self.favorited = attributes[kTwitterKeyValueFavorited];
    
    NSDictionary *placeDict = attributes[kTwitterKeyValuePlace];
    if (![placeDict isEqual:[NSNull null]]) {
        self.placeName = placeDict[kTwitterPlaceKeyName];
        self.countryCode = placeDict[kTwitterPlaceKeyCountryCode];
    }
    
    NSDictionary *userDict = attributes[kTwitterKeyValueUser];
    TwitterUser *newUser = [NSEntityDescription insertNewObjectForEntityForName:@"TwitterUser" inManagedObjectContext:self.managedObjectContext];
    newUser.userID = userDict[kTwitterUserKeyIdNumber];
    newUser.userName = userDict[kTwitterUserKeyName];
    newUser.userRealName = userDict[kTwitterUserScreenName];
    newUser.location = userDict[kTwitterUserKeyLocation];
    Image *newProfileImage = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:self.managedObjectContext];
    newProfileImage.remotePath = userDict[kTwitterUserKeyProfileImage];
    
    newUser.profileImage = newProfileImage;
    
    self.user = newUser;
    

    NSDictionary *coordinateDictionary = attributes[kTwitterKeyValueCoordinate];
    if (![coordinateDictionary isEqual:[NSNull null]]) {
        NSArray *locationArray = coordinateDictionary[kTwitterKeyValueCoordinate];
        if (locationArray.count > 0) {
            Geo *newGeo = [NSEntityDescription insertNewObjectForEntityForName:@"Geo" inManagedObjectContext:self.managedObjectContext];
            
            newGeo.lat = [locationArray objectAtIndex:1];
            newGeo.longituted = [locationArray objectAtIndex:0];
            self.geo = newGeo;
        }
    }
    NSDictionary *entities = attributes[kTwitterKeyValueEntities];
    if (![entities isEqual:[NSNull null]]) {
        self.urls = entities[kEntityKeyURL];
        self.hastags = entities[kEntityKeyHashtags];
    }
}

- (void)updateWithAttributes:(NSDictionary *)attributes{
    self.body = attributes[kTwitterKeyValueText];
    self.favorited = attributes[kTwitterKeyValueFavorited];
    
    NSDictionary *coordinateDictionary = attributes[kTwitterKeyValueCoordinate];
    if (![coordinateDictionary isEqual:[NSNull null]]) {
        NSArray *locationArray = coordinateDictionary[kTwitterKeyValueCoordinate];
        if (locationArray.count > 0) {
            Geo *newGeo = [NSEntityDescription insertNewObjectForEntityForName:@"Geo" inManagedObjectContext:self.managedObjectContext];
            
            newGeo.lat = [locationArray objectAtIndex:1];
            newGeo.longituted = [locationArray objectAtIndex:0];
            self.geo = newGeo;
        }
    }
    NSDictionary *entities = attributes[kTwitterKeyValueEntities];
    if ([entities isEqual:[NSNull null]]) {
        self.urls = entities[kEntityKeyURL];
        self.hastags = entities[kEntityKeyHashtags];
    }
}
@end
