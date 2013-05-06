//
//  Image.m
//  TwitterFeedReader
//
//  Created by Steve_Sanchez on 5/5/13.
//  Copyright (c) 2013 ApargoLLC. All rights reserved.
//

#import "Image.h"
#import <ImageIO/ImageIO.h>

@interface Image (PrimitiveAccessors)
- (NSString *)primitiveLocalPath;

@end

#define kFolderPath [[APGAppDelegate appDelegate].cachePath stringByAppendingPathComponent:@"downloadedImages"]
@interface Image ()
@property (nonatomic, unsafe_unretained, readwrite) BOOL thumbnailIsPlaceHolder;
@property (unsafe_unretained, nonatomic) BOOL shouldSaveToCoreDate;
@property (nonatomic, strong) CPTNetworkRetryOperation *retryOperation;
@end

@implementation Image

@dynamic remotePath;
@dynamic localPath;
@dynamic thumbnailPath;
@dynamic profileImage;
@dynamic tweetImage;
@synthesize fullSizeImage = _fullSizeImage;
@synthesize thumbnailImage = _thumbnailImage;
@synthesize thumbnailIsPlaceHolder = _thumbnailIsPlaceHolder;
@synthesize shouldSaveToCoreDate = _shouldSaveToCoreDate;
@synthesize retryOperation = _retryOperation;


- (UIImage *)fullSizeImage{
    if (!self->_fullSizeImage) {
        if (self.localPath.length > 0){
            
            
            dispatch_queue_t addImageQueue;
            
            addImageQueue = dispatch_queue_create("com.addImageQueue", DISPATCH_QUEUE_CONCURRENT);
            
            NSString *filePath = self.localPath;
            
            [self willAccessValueForKey:@"localPath"];
            NSString *theLocalPath = [self primitiveLocalPath];
            [self didAccessValueForKey:@"localPath"];
            
            if (filePath.length == 0) {
                return self->_fullSizeImage = [UIImage imageNamed:@"noPic.png"];
            }
            NSString *dispatchPath = [theLocalPath copy];
            
            dispatch_queue_t dispatchQueue = dispatch_queue_create("com.hellovino.imageget", DISPATCH_QUEUE_CONCURRENT);
            dispatch_async(dispatchQueue, ^{
                UIImage *image = [UIImage imageWithContentsOfFile:dispatchPath];
                if (image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self willChangeValueForKey:@"fullSizeImage"];
                        self.fullSizeImage = image;
                        [self didChangeValueForKey:@"fullSizeImage"];
                    });
                }
            });
            
        }else if (self.remotePath.length > 0){
            self.thumbnailIsPlaceHolder = YES;  
            self->_fullSizeImage = [UIImage imageNamed:@"noPic.png"];
            self.shouldSaveToCoreDate = NO;
            [self startImageGet];
        }else {
            self->_fullSizeImage = [UIImage imageNamed:@"noPic.png"];
        }
    }
    return self->_fullSizeImage;
}

- (UIImage *)thumbnailImage{
    if (!self->_thumbnailImage) {
        if (self.thumbnailPath.length > 0) {
            self->_thumbnailImage = [UIImage imageWithContentsOfFile:self.thumbnailPath];
        }else{
            self->_thumbnailImage = [UIImage imageNamed:@"noPic.png"];
            [self startThumbnailGet];
        }
    }
    return self->_thumbnailImage;
}

- (void)startImageGet{
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.remotePath]];
    
    if (!request) {
        NSLog(@"There was an error building the image request remote path == %@", self.remotePath);
    }else{
        self.retryOperation = [[CPTNetworkRetryOperation alloc] initWithRequest:request];
        [self.retryOperation setQueuePriority:NSOperationQueuePriorityLow];
        self.retryOperation.acceptableContentTypes = [NSSet setWithObjects:@"image/jpg",@"image/jpeg", @"image/png", nil];
        [[CPTOperationAndRunLoopManager sharedManager] addNetworkManagementOperation:self.retryOperation finishedTarget:self action:@selector(finishedImageGet:)];
    }
}

- (void)startThumbnailGet{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.remotePath]];
    
    self.retryOperation = [[CPTNetworkRetryOperation alloc] initWithRequest:request];
    [self.retryOperation setQueuePriority:NSOperationQueuePriorityLow];
    self.retryOperation.acceptableContentTypes = [NSSet setWithObjects:@"image/jpg",@"image/jpeg", @"image/png", nil];
    [[CPTOperationAndRunLoopManager sharedManager] addNetworkManagementOperation:self.retryOperation finishedTarget:self action:@selector(finishedThumbnailGet:)];
}

- (void)finishedImageGet:(CPTNetworkRetryOperation *)operation{
    assert([NSThread isMainThread]);
    assert([operation isKindOfClass:[CPTNetworkRetryOperation class]]);
    assert([self.retryOperation isFinished]);
    
    UIImage *img = [UIImage imageWithData:operation.responseContent];
    [self imageCommit:img objectId:self.objectID];
}

- (void)finishedThumbnailGet:(CPTNetworkRetryOperation *)operation{
    assert([NSThread isMainThread]);
    assert([operation isKindOfClass:[CPTNetworkRetryOperation class]]);
        //assert([self.retryOperation isFinished]);
    
    self.retryOperation = nil;
    
    UIImage *img = [UIImage imageWithData:operation.responseContent];
    [self thumbnailCommitImage:img];
}

- (void)thumbnailCommitImage:(UIImage *)localImage{
    if (!localImage) {
        localImage = [UIImage imageNamed:@"noPic.png"];
        assert(localImage != nil);
    }
    
    dispatch_queue_t imageIOQueue = dispatch_queue_create("com.imageIO.queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(imageIOQueue, ^{
        UIImage *retval = nil;
        CFDictionaryRef options = NULL;
        CFStringRef keys[3];
        CFTypeRef values[3];
        CFNumberRef thumbnailSize;
        CGFloat photoSizeMax = 60.0;
        CGImageRef localImageRef = NULL;
        
        thumbnailSize = CFNumberCreate(NULL, kCFNumberIntType, &photoSizeMax);
        CGImageSourceRef imageSourceRef = NULL;
        
        NSError *localDataError = nil;
        NSData *data = UIImagePNGRepresentation(localImage);
        if (!localDataError) {
            imageSourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)(data), NULL);
            
            keys[0] = kCGImageSourceCreateThumbnailWithTransform;
            values[0] = (CFTypeRef)kCFBooleanTrue;
            keys[1] = kCGImageSourceCreateThumbnailFromImageAlways;
            values[1] = (CFTypeRef)kCFBooleanTrue;
            keys[2] = kCGImageSourceThumbnailMaxPixelSize;
            values[2] = (CFTypeRef)thumbnailSize;
            
            options = CFDictionaryCreate(NULL, (const void **)keys, (const void **)values, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            localImageRef = CGImageSourceCreateImageAtIndex(imageSourceRef, 0, options);
            CFRelease(thumbnailSize);
            CFRelease(options);
            CFRelease(imageSourceRef);
            retval = [UIImage imageWithCGImage:localImageRef];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.thumbnailImage = retval;
                [self commitThumbnailData:retval];
                [self willChangeValueForKey:@"thumbnailImage"];
                [self didChangeValueForKey:@"thumbnailImage"];
            });
        }
    });
}

- (void)imageCommit:(UIImage *)localImage objectId:(NSManagedObjectID *)objId{
    if (!localImage) {
        localImage = [UIImage imageNamed:@"noPic.png"];
        assert(localImage != nil);
    }
    
    dispatch_queue_t imageCommitQueue;
    
    imageCommitQueue = dispatch_queue_create("com.apargo.commitThread", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(imageCommitQueue, ^{
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
        context.persistentStoreCoordinator = [CPTDataAccess sharedAccess].managedObjectContext.persistentStoreCoordinator;
        Image *threadSafeImage = (Image *)[context objectRegisteredForID:objId];
        [threadSafeImage commitData:localImage];
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
            [self willChangeValueForKey:@"fullSizeImage"];
            self.fullSizeImage = localImage;
            [self didChangeValueForKey:@"fullSizeImage"];
    });
}

- (void)commitData:(UIImage *)imageLocal{
    NSString *fileName = [self.remotePath lastPathComponent];
    
    fileName = [[self directoryPath] stringByAppendingPathComponent:fileName];
    if (fileName) {
        NSData *data = UIImagePNGRepresentation(imageLocal);
        if (![data writeToFile:fileName atomically:YES]) {
            NSLog(@"There was an error writing the image to the file system error = nil");
        }else {
            self.localPath = fileName;
            NSError *error = nil;
            [self.managedObjectContext save:&error];
            NSLog(@"error = %@", error);
        }
    }
}

- (void)commitThumbnailData:(UIImage *)imageLocal{
    NSString *fileName = [self.remotePath lastPathComponent];
    
    fileName = [[self directoryPath] stringByAppendingPathComponent:fileName];
    if (fileName) {
        NSData *data = UIImagePNGRepresentation(imageLocal);
        if (![data writeToFile:fileName atomically:YES]) {
            NSLog(@"There was an error writing the image to the file system error = nil");
        }else {
            self.thumbnailPath = fileName;
            NSError *error = nil;
            [self.managedObjectContext save:&error];
            NSLog(@"error = %@", error);
        }
    }
}

- (NSString *)directoryPath{
    NSString *retVal = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:[kFolderPath copy]]) {
        NSError *error = nil;
        if ([fm createDirectoryAtPath:[kFolderPath copy] withIntermediateDirectories:NO attributes:nil error:&error]) {
            retVal = [kFolderPath copy];
        }else {
            NSLog(@"There was an error creting the folder for images error == %@", error);
        }
    }else {
        retVal = [kFolderPath copy];
    }
    return retVal;
}
@end
