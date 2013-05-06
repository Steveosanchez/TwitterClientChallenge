//
//  APGTwitterFeedRefresh.m
//  TwitterFeedReader
//
//  Created by Steve_Sanchez on 5/5/13.
//  Copyright (c) 2013 ApargoLLC. All rights reserved.
//

#import "APGTwitterFeedRefresh.h"
#import "Tweet.h"
#import <Accounts/Accounts.h>


#define kSaveOnNumber 100

@interface APGTwitterFeedRefresh ()
@property (strong, nonatomic) CPTNetworkRetryOperation *retryOperation;
@property (strong, nonatomic) NSManagedObjectContext *localContext;
@property (strong, nonatomic) NSFetchedResultsController *resultsController;
@property (strong, nonatomic) NSThread *currentThread;
@end



@implementation APGTwitterFeedRefresh

- (void)operationDidStart{
    [self addObserver:self forKeyPath:@"retryOperation.isNetworkReachable" options:NSKeyValueObservingOptionNew context:&self->_retryOperation];
    
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccount = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    __block ACAccount *account = nil;
    self.currentThread = [NSThread currentThread];
    
    [store requestAccessToAccountsWithType:twitterAccount options:nil completion:^(BOOL granted, NSError *error){
        
        if (granted) {
            NSArray *array = [store accounts];
            account = [array objectAtIndex:0];
            
            
            SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"] parameters:nil];
            
                //Because the performRequestWithHandler: method has a request handler that is not gaurnteed to be called on any particular thread and we are running in the background and in our own
                //RunLoop it is better for us to get the request and handle it ourselves.
            request.account = account;
            
            NSURLRequest *preparedRequest = [request preparedURLRequest];
            
            [self performSelector:@selector(runOperation:) onThread:self.currentThread withObject:preparedRequest waitUntilDone:NO];
            
        }
    }];
}

- (void)runOperation:(NSURLRequest *)preparedRequest{
    self.retryOperation = [[CPTNetworkRetryOperation alloc] initWithRequest:preparedRequest];
    [[CPTOperationAndRunLoopManager sharedManager] addNetworkManagementOperation:self.retryOperation finishedTarget:self action:@selector(completedRequest:)];
}


- (void)completedRequest:(CPTNetworkRetryOperation *)operation{
    if (!operation.error) {
        NSString *dataString = [[NSString alloc] initWithData:operation.responseContent encoding:NSUTF8StringEncoding];
        
        NSLog(@"The response JSON From twitter \n %@", dataString);
        
        NSInputStream *stream = [NSInputStream inputStreamWithData:operation.responseContent];
        [stream open];
        
        NSError *jsonReadError = nil;
        NSArray *results = [NSJSONSerialization JSONObjectWithStream:stream options:0 error:&jsonReadError];
        [stream close];
        
        if (jsonReadError) {
            NSLog(@"There was a Json Read error, The error \n %@ user info \n %@", jsonReadError, jsonReadError.userInfo);
            [self finishWithError:jsonReadError];
        }
        NSArray *sortedArray = [results sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
            
            NSString *objId1 = (NSString *)obj1[@"id_str"];
            NSString *objId2 = (NSString *)obj2[@"id_str"];
            
            return [objId1 compare:objId2];
        }];
        
        NSInteger numberOfCoreDataObjects = 0;
        if ([self.resultsController sections].count > 0) {
            numberOfCoreDataObjects = [[[self.resultsController sections] objectAtIndex:0] numberOfObjects];
        }
        NSInteger numberOfDataObjects = sortedArray.count;
        
        NSInteger coredataPointer = 0;
        NSInteger dataArrayPointer = 0;
        NSInteger saveCounter = 0;
        
        BOOL coreDataHasMoreObjects = (coredataPointer < numberOfCoreDataObjects);
        BOOL dataArrayHasMoreObjects = (dataArrayPointer < numberOfDataObjects);
        
        @autoreleasepool {
            while (dataArrayHasMoreObjects || coreDataHasMoreObjects) {
                if (!coreDataHasMoreObjects) {
                    do {
                        Tweet *newTweet = [NSEntityDescription insertNewObjectForEntityForName:@"Tweet" inManagedObjectContext:self.localContext];
                        [newTweet buildNewTweetWithAttributes:[sortedArray objectAtIndex:dataArrayPointer]];
                        dataArrayPointer ++;
                        dataArrayHasMoreObjects = (dataArrayPointer < numberOfDataObjects);
                    } while (dataArrayHasMoreObjects);
                }else if (!dataArrayHasMoreObjects){
                    coreDataHasMoreObjects = NO;
                }else {
                    Tweet *tweet = [self.resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:coredataPointer inSection:0]];
                    [self.localContext processPendingChanges];
                    
                    NSString *coreDataIdNumber = tweet.tweetId;
                    
                    NSDictionary *attributes = [sortedArray objectAtIndex:dataArrayPointer];
                    
                    NSString *dataIdString = attributes[@"id_str"];
                    NSString *dateIdNumber = dataIdString;
                    
                    NSComparisonResult comparison = [coreDataIdNumber compare:dateIdNumber];
                    
                    if (comparison == NSOrderedDescending) {
                        Tweet *newTweet = [NSEntityDescription insertNewObjectForEntityForName:@"DealsSectionDeal" inManagedObjectContext:self.localContext];
                        [newTweet buildNewTweetWithAttributes:attributes];
                        dataArrayPointer ++;
                        dataArrayHasMoreObjects = (dataArrayPointer < numberOfDataObjects);
                    }else if (comparison == NSOrderedAscending){
                        coredataPointer++;
                        coreDataHasMoreObjects = (coredataPointer < numberOfCoreDataObjects);
                    }else if (comparison == NSOrderedSame){
                        [tweet updateWithAttributes:attributes];
                        dataArrayPointer ++;
                        dataArrayHasMoreObjects = (dataArrayPointer < numberOfDataObjects);
                        coredataPointer++;
                        coreDataHasMoreObjects = (coredataPointer < numberOfCoreDataObjects);
                    }
                }
                
                saveCounter ++;
                
                if (saveCounter >= kSaveOnNumber) {
                    NSError *saveError = nil;
                    
                    if (![self.localContext save:&saveError]) NSLog(@"There was an issue saving the Deals during update error == %@", saveError);
                    saveCounter = 0;
                }
            }
            
            NSError *saveError = nil;
            if (![self.localContext save:&saveError]) NSLog(@"There was an issue saving the Deals during update error == %@", saveError);
        }
        [self finishWithError:nil];
    }else{
        [self finishWithError:operation.error];
    }
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if (context == &self->_retryOperation) {
        if ([keyPath isEqualToString:@"retryOperation.isNetworkReachable"]) {
                //Do something here.
        }
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -
#pragma mark Getter Overrides (Lazy Loading)

- (NSManagedObjectContext *)localContext{
    if (!self->_localContext) {
        self->_localContext = [[NSManagedObjectContext alloc] init];
        self->_localContext.persistentStoreCoordinator = [CPTDataAccess sharedAccess].managedObjectContext.persistentStoreCoordinator;
        self->_localContext.undoManager = nil;
        [self->_localContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    }
    return self->_localContext;
}

- (NSFetchedResultsController *)resultsController{
    if (!self->_resultsController) {
        NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"Tweet"];
        [fetch setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"tweetId" ascending:YES]]];
        self->_resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetch managedObjectContext:self.localContext sectionNameKeyPath:nil cacheName:nil];
        NSError *error = nil;
        
        if (![self->_resultsController performFetch:&error]) {
            NSLog(@"There was an error Performing the fetch error \n %@  user info \n %@", error, error.userInfo);
            [self finishWithError:error];
        }
    }
    return self->_resultsController;
}

- (void)dealloc{
    [self removeObserver:self forKeyPath:@"retryOperation.isNetworkReachable" context:&self->_retryOperation];
    
}
@end
