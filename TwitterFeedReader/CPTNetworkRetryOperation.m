//
//  CPTNetworkRetryOperation.m
//  CrossPointMedia
//
//  Created by Steve_Sanchez on 6/21/12.
//  Copyright (c) 2012 Apargo. All rights reserved.
//

#import "CPTNetworkRetryOperation.h"
#import "CPTOperationAndRunLoopManager.h"

@interface CPTNetworkRetryOperation(){
    NSUInteger                      _sequenceNumber;
    NSURLRequest                   *_request;
    NSSet                          *_acceptableContentTypes;
    NSString                       *_responseFilePath;
    NSHTTPURLResponse              *_response;
    NSData                         *_responseContent;
    NetworkRetryOperationState      _retryState;
    NetworkRetryOperationState      _retryClientState;
    CPTBaseNetworkOperation           *_networkOperation;
    BOOL                            _hasHadRetryableFailure;
    NSUInteger                      _retryCount;
    NSTimer                        *_retryTimer;
    CPTReachabilityOperation          *_reachabilityOperation;
    BOOL                            _notificationInstalled;
    BOOL                            _isNetworkReachable;
}


@property (unsafe_unretained, readwrite) NetworkRetryOperationState retryState;
@property (unsafe_unretained, readwrite) NetworkRetryOperationState retryClientState;
@property (unsafe_unretained, readwrite) BOOL                       hasHadRetryableFailure;
@property (unsafe_unretained, readwrite) NSUInteger                 retryCount;
@property (copy, readwrite) NSData                                  *responseContent;
@property (copy, readwrite) NSHTTPURLResponse                       *response;
@property (strong, readwrite) CPTBaseNetworkOperation               *networkOperation;
@property (strong, readwrite) NSTimer                               *retryTimer;
@property (strong, readwrite) CPTReachabilityOperation              *reachabilityOperation;
@property (unsafe_unretained, readwrite) BOOL                       notificationInstalled;
@property (unsafe_unretained, readwrite) BOOL                       isNetworkReachable;

- (void)startRequest;
- (void)startReachability:(BOOL)reachable;
- (void)startRetryAfterTimeInterval:(NSTimeInterval)delay;

@end

static NSString * kNetworkRetryOperationTransferDidSucceedNotification = @"com.apargo.dts.kRetryingHTTPOperationTransferDidSucceedNotification";
static NSString * kNetworkRetryOperationTransferDidSucceedHostKey = @"apgTransferSucceededHostKey";

@implementation CPTNetworkRetryOperation

- (id)initWithRequest:(NSURLRequest *)request{
    self = [super init];
    if (self) {
        @synchronized(self){
            static NSUInteger sSequenceNumber;
            self->_sequenceNumber = sSequenceNumber;
            sSequenceNumber += 1;
            self->_isNetworkReachable = YES;
        }
        self->_request = [request copy];
    }
    return self;
}

- (NetworkRetryOperationState)retryState{
    return self->_retryState;
}

- (void)setRetryState:(NetworkRetryOperationState)newValue{
    self->_retryState = newValue;
    [self performSelectorOnMainThread:@selector(syncRetryClientState) withObject:nil waitUntilDone:NO];
}

- (void)syncRetryClientState{
    assert([NSThread isMainThread]);
    self.retryClientState = self.retryState;
}

- (NSString *)responseMIMEType{
    NSString *result = nil;
    NSHTTPURLResponse *response = self.response;
    
    if (response != nil) {
        result = [response MIMEType];
    }
    
    return  result;
}

- (void)setHasHadRetryableFailureOnMainThread{
    assert([NSThread isMainThread]);
    self.hasHadRetryableFailure = YES;
}

- (BOOL)shouldRetryAfterError:(NSError *)error{
    BOOL shouldRetry = YES;
    
    if ([[error domain] isEqualToString:kBaseNetworkOperationErrorDomain]) {
        if ([error code] > 0) {
            shouldRetry = NO;
        }else{
            switch ([error code]) {
                    
                default:{
                    assert(NO);
                }
                    
                case kBaseNetworkOperationErrorResponseTooLarge:
                case kBaseNetworkOperationErrorOnOutputStreat:
                case kBaseNetworkOperationErrorBadContentType:{
                    shouldRetry = NO;
                    break;
                }

            }
        }
    }else{
        shouldRetry = YES;
    }
    return shouldRetry;
}


- (NSTimeInterval)retryDelayWithinRangeAtIndex:(NSUInteger)rangeIndex{
    static const NSUInteger kRetryDelays[] = {1,60,60 * 60, 6 * 60 * 60};
    
    if (rangeIndex >= (sizeof(kRetryDelays) / sizeof(kRetryDelays[0]))) {
        rangeIndex = (sizeof(kRetryDelays) / sizeof(kRetryDelays [0])) - 1;
    }
    
    return ((NSTimeInterval) (((NSUInteger) arc4random()) % (kRetryDelays[rangeIndex] * 1000))) / 1000.0;
}

- (NSTimeInterval)shortRetryDelay{
    return [self retryDelayWithinRangeAtIndex:0];
}

- (NSTimeInterval)randomRetryDelay{
    return [self retryDelayWithinRangeAtIndex:self.retryCount];
}

- (void)operationDidStart{
    [super operationDidStart];
    self.isNetworkReachable = YES;
    self.retryState = kNetworkOperationStateGetting;
    
    [self startRequest];
}

+ (BOOL)automaticallyNotifiesObserversOfIsNetworkReachable{
    return NO;
}
- (void)startRequest{
    self.networkOperation = [[CPTBaseNetworkOperation alloc] initWithRequest:self.request];
    
    [self.networkOperation setQueuePriority:[self queuePriority]];
    self.networkOperation.acceptableContentTypes = self.acceptableContentTypes;
    self.networkOperation.runLoopModes = self.runLoopModes;
    self.networkOperation.runloopThread = self.runloopThread;
    
    if (self.responseFilePath != nil) {
        self.networkOperation.responseOutputStream = [NSOutputStream outputStreamToFileAtPath:self.responseFilePath append:NO];
    }
    [[CPTOperationAndRunLoopManager sharedManager] addNetworkTransferOperation:self.networkOperation finishedTarget:self action:@selector(networkOperationDone:)];
    
}

- (void)networkOperationDone:(CPTBaseNetworkOperation *)operation{
    self.networkOperation = nil;
    
    if (operation.error == nil) {
        self.response = operation.lastResponse;
        self.responseContent = operation.responseBody;
        [self finishWithError:nil];
    }else{
        
        if (![self shouldRetryAfterError:operation.error]) {
            [self finishWithError:operation.error];
        }else{
            if (self.retryState == kNetworkOperationStateGetting) {
                [self performSelectorOnMainThread:@selector(setHasHadRetryableFailureOnMainThread) withObject:nil waitUntilDone:NO];
            }
            
            if (!self.notificationInstalled) {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transferDidSucceed:) name:kNetworkRetryOperationTransferDidSucceedNotification object:nil];
                self.notificationInstalled = YES;
            }
            
            if (self.reachabilityOperation == nil) {
                [self startReachability:NO];
            }
            
            self.retryState = kNetworkOperationStateWaitingToRetry;
            [self startRetryAfterTimeInterval:[self randomRetryDelay]];
        }
    }
}


- (void)transferDidSucceed:(NSNotification *)note{
    if ([[[note userInfo] objectForKey:kNetworkRetryOperationTransferDidSucceedNotification] isEqual:[[self.request URL] host]]) {
        [self performSelector:@selector(transferDidSucceedOnRunLoopThread) onThread:self.actualRunLoopThread withObject:nil waitUntilDone:NO];
    }
}

- (void)transferDidSucceedOnRunLoopThread{
    if (self.retryState == kNetworkOperationStateWaitingToRetry) {
        [self.retryTimer invalidate];
        [self startRetryAfterTimeInterval:[self shortRetryDelay]];
    }
}

- (void)startRetryAfterTimeInterval:(NSTimeInterval)delay{
    self.retryTimer = [NSTimer timerWithTimeInterval:delay target:self selector:@selector(retryTimerDone:) userInfo:nil repeats:NO];
    for (NSString *mode in self.actualRunLoopModes) {
        [[NSRunLoop currentRunLoop] addTimer:self.retryTimer forMode:mode];
    }
}

- (void)retryTimerDone:(NSTimer *)timer{
    [self.retryTimer invalidate];
    self.retryState = kNetworkOperationStateRetrying;
    self.retryCount += 1;
    [self startRequest];
}

- (void)startReachability:(BOOL)reachable{
    
    assert(self.reachabilityOperation == nil);
    self.reachabilityOperation = [[CPTReachabilityOperation alloc] initWithHostName:[[self.request URL] host]];
    assert(self.reachabilityOperation != nil);
    
    if (! reachable) {
        self.reachabilityOperation.flagsTargetMask = kSCNetworkReachabilityFlagsReachable;
        self.reachabilityOperation.flagsTargetValue = 0;
    }
    
    [self.reachabilityOperation setQueuePriority:[self queuePriority]];
    self.reachabilityOperation.runloopThread = self.runloopThread;
    self.reachabilityOperation.runLoopModes = self.runLoopModes;
    
    [[CPTOperationAndRunLoopManager sharedManager] addNetworkManagementOperation:self.reachabilityOperation finishedTarget:self action:@selector(reachabilityOperationDone:)];
}

- (void)reachabilityOperationDone:(CPTReachabilityOperation*)operation{
    
    assert([self isActualRunLoopThread]);
    assert(self.retryState >= kNetworkOperationStateWaitingToRetry);
    assert(operation == self.reachabilityOperation);
    self.reachabilityOperation = nil;
    assert(operation.error == nil);
    
    if (! (operation.flags & kSCNetworkReachabilityFlagsReachable) ) {
        [self willChangeValueForKey:@"isNetworkReachable"];
        self.isNetworkReachable = NO;
        [self didChangeValueForKey:@"isNetworkReachable"];
        [self startReachability:YES];
    }else{
        self.isNetworkReachable = YES;
        if (self.retryState == kNetworkOperationStateWaitingToRetry) {
            assert(self.retryTimer != nil);
            [self.retryTimer invalidate];
            [self startRetryAfterTimeInterval:[self shortRetryDelay] + 3.0];
        }
    }
}

- (void)operationWillFinish{
    [super operationWillFinish];
    
    if (self.networkOperation != nil) {
        [[CPTOperationAndRunLoopManager sharedManager] cancelOperation:self.networkOperation];
        self.networkOperation = nil;
    }
    
    if (self.retryTimer != nil) {
        [self.retryTimer invalidate];
        self.retryTimer = nil;
    }
    
    if (self.reachabilityOperation != nil) {
        
        [[CPTOperationAndRunLoopManager sharedManager] cancelOperation:self.reachabilityOperation];
        self.reachabilityOperation = nil;
    }
    
    if (self.notificationInstalled) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kNetworkRetryOperationTransferDidSucceedNotification object:nil];
        self.notificationInstalled = NO;
    }
    
    self.retryState = kNetworkOperationStateFinished;
    
    if (self.error == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNetworkRetryOperationTransferDidSucceedNotification object:nil userInfo:@{ [[self.request URL] host] : kNetworkRetryOperationTransferDidSucceedHostKey }];
    }else{
        //should probably log this.
    }
}


@end
