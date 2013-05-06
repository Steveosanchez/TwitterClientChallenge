//
//  CPTDataAccess.m
//  CrossPointMedia
//
//  Created by Steve_Sanchez on 6/25/12.
//  Copyright (c) 2012 Apargo. All rights reserved.
//

#import "CPTDataAccess.h"
#import "APGAppDelegate.h"


@interface CPTDataAccess(){
    //User Data
    NSPersistentStoreCoordinator    *_userDataPersistentStoreCoordinator;
    NSManagedObjectModel            *_userDataManagedObjectModel;
    NSManagedObjectContext          *_userDataManagedObjectContext;
}


- (void)storeUserManagedObjectContextForThread:(NSManagedObjectContext*)context;
- (NSString *)userThreadContextKey;

@end


NSString * const UserThreadManagedObjectContext = @"UserThreadManagedObjectContext";
NSString * const UserDirectory = @"UserDirectory";
NSString * const UserStorageName = @"Data.sqlite";




@implementation CPTDataAccess


+ (CPTDataAccess *)sharedAccess{
    static CPTDataAccess *access;
    
    if (access == nil) {
        @synchronized(self){
            if (access == nil) {
                access = [[CPTDataAccess alloc] init];
            }
        }
    }
    return access;
}
- (NSString *)userThreadContextKey{
    return [NSString stringWithFormat:@"%@-%@", UserThreadManagedObjectContext, self.class];
}


- (void)storeUserManagedObjectContextForThread:(NSManagedObjectContext *)context{
    [[[NSThread currentThread] threadDictionary] setObject:context forKey:[self userThreadContextKey]];
}



#pragma Core Data Setup User


- (NSManagedObjectContext *)managedObjectContext{
    NSManagedObjectContext * storedContext = [[[NSThread currentThread] threadDictionary] objectForKey:UserThreadManagedObjectContext];
    
    if (storedContext != nil) return storedContext;
    NSManagedObjectContext *moc = [self buildUserManagedObjectContext];
    [self storeUserManagedObjectContextForThread:moc];
    return moc;
}


- (NSManagedObjectContext *)buildUserManagedObjectContext{
    NSPersistentStoreCoordinator *coordinator = [self userPersistentStoreStoreCoordinator];
    
    if (coordinator != nil) {
        NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init];
        [moc setPersistentStoreCoordinator:coordinator];
        return moc;
    }
    
    return nil;
}

- (NSPersistentStoreCoordinator *)userPersistentStoreStoreCoordinator{
    if (self->_userDataPersistentStoreCoordinator != nil) return self->_userDataPersistentStoreCoordinator;
    
    NSString *storePath = [[self userStoragePath] stringByAppendingPathComponent:[self userStorageName]];
    NSError *error = nil;
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    
    self->_userDataPersistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self userMangedObjectModel]];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, NSFileProtectionComplete, NSPersistentStoreFileProtectionKey, nil];
    if (![self->_userDataPersistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
#ifdef DEBUG
        //This is a hard crash that developers should see only!!! 
        
        //NSLog(@"CoreData Error %@, %@", error, [error userInfo]);
        abort();
#else
        if ([[NSFileManager defaultManager] fileExistsAtPath:storePath]) {
            NSError *removeError = nil;
            if ([[NSFileManager defaultManager] removeItemAtPath:storePath error:&removeError]) {
                return [self userPersistentStoreStoreCoordinator];
            }else{
                NSLog(@"There was an error removing the Database %@, %@", removeError, [removeError userInfo]);
                abort();
            }
        }else{
            NSLog(@"The CoreData file was not at the place we thought it was %@, %@", error, [error userInfo]);
            abort();
        }
        
#endif
    }
    
    return self->_userDataPersistentStoreCoordinator;
}

- (NSManagedObjectModel *)userMangedObjectModel{
    if (self->_userDataManagedObjectModel != nil) return self->_userDataManagedObjectModel;
    
    //NSLog(@"Using model: %@", [self userModelName]);
    
    NSString *momPath = [[NSBundle mainBundle] pathForResource:[self userModelName] ofType:@"momd"];
    if (!momPath) {
        momPath = [[NSBundle bundleForClass:[self class]] pathForResource:[self userModelName] ofType:@"mom"];
    }
    
    if (momPath) {
        NSURL *momURL = [NSURL fileURLWithPath:momPath];
        if (momURL) self->_userDataManagedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
    }
    
    return self->_userDataManagedObjectModel;
}


#pragma Abstract Methods

- (NSString *)userModelName{
    return [NSString stringWithFormat:@"TweetModel"];
}

- (NSString *)userStorageName{
    return [NSString stringWithFormat:@"tweetData.sqlite"];
}


- (NSString *)userStoragePath{
    
    NSString *pathForDB = [[[APGAppDelegate appDelegate] documentsPath] stringByAppendingPathComponent:@"appData"];
    NSError *error = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathForDB]) {
        return pathForDB;
    }else{
        if ([[NSFileManager defaultManager] createDirectoryAtPath:pathForDB withIntermediateDirectories:NO attributes:nil error:&error]) {
            return pathForDB;
        }
    }
    return nil;
}

@end
