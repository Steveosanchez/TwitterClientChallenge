//
//  Image.h
//  TwitterFeedReader
//
//  Created by Steve_Sanchez on 5/5/13.
//  Copyright (c) 2013 ApargoLLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Image : NSManagedObject

@property (nonatomic, retain) NSString * remotePath;
@property (nonatomic, retain) NSString * localPath;
@property (nonatomic, retain) NSString * thumbnailPath;
@property (nonatomic, retain) NSManagedObject *profileImage;
@property (nonatomic, retain) NSManagedObject *tweetImage;
@property (nonatomic, strong) UIImage *fullSizeImage;
@property (nonatomic, strong) UIImage *thumbnailImage;

@end
