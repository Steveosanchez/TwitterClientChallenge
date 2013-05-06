//
//  CPTDataAccess.h
//  CrossPointMedia
//
//  Created by Steve_Sanchez on 6/25/12.
//  Copyright (c) 2012 Apargo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CPTDataAccess : NSObject

@property (strong, nonatomic) NSPersistentStoreCoordinator *userPersistentStoreStoreCoordinator;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

+ (CPTDataAccess *)sharedAccess; //Singleton not necessarily thread safe

@end
