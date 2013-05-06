//
//  CPTOperationAndRunLoopManager.m
//  CrossPointMedia
//
//  Created by Steve_Sanchez on 6/22/12.
//  Copyright (c) 2012 Apargo. All rights reserved.
//

#import "CPTOperationAndRunLoopManager.h"

@interface CPTOperationAndRunLoopManager (){
    NSThread              * _networkRunLoopThread;
    NSThread              * _cpuRunLoopThread;
    NSThread              * _updateCPURunLoopThread;
    NSThread              * _secondaryUpdateThread;
    NSOperationQueue      * _queueForNetworkManagement;
    NSOperationQueue      * _queueForNetworkTransfers;
    NSOperationQueue      * _queueForCPU;
    NSOperationQueue      * _queueForCPURunLoopOpearations;
    NSOperationQueue      * _queueForSecondaryRunLoopOperations;
    NSOperationQueue      * _queueForCPUUpdateOperations;
    CFMutableDictionaryRef  _runningOperationToTragetMap;
    CFMutableDictionaryRef  _runningOperationToThreadMap;
    CFMutableDictionaryRef  _runningOperationToActionMap;
    NSUInteger              _runningNetworkTransferCount;
}

@property (strong, nonatomic, readonly) NSThread * networkRunLoopThread;
@property (strong, nonatomic, readonly) NSThread * cpuRunLoopThread;
@property (strong, nonatomic, readonly) NSThread * updateCPURunLoopThread;
@property (strong, nonatomic, readonly) NSThread * secondaryUpdateThread;
@property (strong, nonatomic, readonly) NSOperationQueue * queueForNetworkTransfers;
@property (strong, nonatomic, readonly) NSOperationQueue * queueForNetworkManagement;
@property (strong, nonatomic, readonly) NSOperationQueue * queueForCPU;
@property (strong, nonatomic, readonly) NSOperationQueue * queueForCPURunLoopOpearations;
@property (strong, nonatomic, readonly) NSOperationQueue * queueForCPUUpdateOperations;
@property (strong, nonatomic, readonly) NSOperationQueue * queueForSecondaryRunLoopOperations;

@end


@implementation CPTOperationAndRunLoopManager

+ (CPTOperationAndRunLoopManager *)sharedManager{
    static CPTOperationAndRunLoopManager *sRunLoopManager;
    
    if (sRunLoopManager == nil) {
        @synchronized(self){
            sRunLoopManager = [[CPTOperationAndRunLoopManager alloc] init];
        }
    }
    return sRunLoopManager;
}


- (id)init{
    self = [super init];
    if (self) {
        self->_queueForNetworkManagement = [[NSOperationQueue alloc] init];
        [self->_queueForNetworkManagement setMaxConcurrentOperationCount:NSIntegerMax];
        self->_queueForNetworkTransfers = [[NSOperationQueue alloc] init];
        [self->_queueForNetworkTransfers setMaxConcurrentOperationCount:4];
        self->_queueForCPU = [[NSOperationQueue alloc] init];
        [self->_queueForCPU setMaxConcurrentOperationCount:4];
        self->_queueForCPURunLoopOpearations = [[NSOperationQueue alloc] init];
        [self->_queueForCPURunLoopOpearations setMaxConcurrentOperationCount:10];
        self->_queueForCPUUpdateOperations = [[NSOperationQueue alloc] init];
        [self->_queueForCPUUpdateOperations setMaxConcurrentOperationCount:10];
        self->_queueForSecondaryRunLoopOperations = [[NSOperationQueue alloc] init];
        
        [self->_queueForSecondaryRunLoopOperations setMaxConcurrentOperationCount:3];
        
        self->_runningOperationToTragetMap = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        self->_runningOperationToActionMap = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, NULL);
        self->_runningOperationToThreadMap = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        
        
        self->_networkRunLoopThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkRunLoopThreadEntry) object:nil];
        
        [self->_networkRunLoopThread setName:@"com.apargo.networkThread"];
        
        [self->_networkRunLoopThread setThreadPriority:0.3];
        [self->_networkRunLoopThread start];
        
        self->_cpuRunLoopThread = [[NSThread alloc] initWithTarget:self selector:@selector(cpuRunLoopThreadEntry) object:nil];
        [self->_cpuRunLoopThread setName:@"com.apargo.cpuThread"];
        [self->_cpuRunLoopThread setThreadPriority:0.3];
        [self->_cpuRunLoopThread start];
        
        self->_updateCPURunLoopThread = [[NSThread alloc] initWithTarget:self selector:@selector(cpuUpdateRunLoopThreadEntry) object:nil];
        [self->_updateCPURunLoopThread setName:@"com.apargo.updateThread"];
        [self->_updateCPURunLoopThread setThreadPriority:0.3];
        [self->_updateCPURunLoopThread start];
        
        self->_secondaryUpdateThread = [[NSThread alloc] initWithTarget:self selector:@selector(secondaryUpdateThreadEntry) object:nil];
        [self->_secondaryUpdateThread setName:@"comp.apargo.secondaryUpdateThread"];
        [self->_secondaryUpdateThread setThreadPriority:0.3];
        [self->_secondaryUpdateThread start];
    }
    
    return self;
}


- (NSMutableURLRequest *)requestToGetURL:(NSURL *)url{
    NSMutableURLRequest *result = [NSMutableURLRequest requestWithURL:url];
    static NSString *sUserAgentString;
    
    if (sUserAgentString == nil) {
        sUserAgentString = [[NSString alloc] initWithFormat:@"WebMDPainApp/%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleVersionKey]];
    }
    [result setValue:sUserAgentString forHTTPHeaderField:@"User-Agent"];
    return result;
}


- (void)networkRunLoopThreadEntry{
    while (YES) {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] run];
        }
    }
}

- (void)cpuRunLoopThreadEntry{
    while (YES) {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] run];
        }
    }
}

- (void)cpuUpdateRunLoopThreadEntry{
    while (YES) {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] run];
        }
    }
}

- (void)secondaryUpdateThreadEntry{
    while (YES) {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] run];
        }
    }
}

- (BOOL)networkInUse{
    return self->_runningNetworkTransferCount != 0;
}

- (void)incrementRunningNetworkTransferCount{
    BOOL movingToInUse = (self->_runningNetworkTransferCount == 0);
    
    if (movingToInUse) {
        [self willChangeValueForKey:@"networkInUse"];
        
    }
    
    self->_runningNetworkTransferCount += 1;
    
    if (movingToInUse) {
        [self didChangeValueForKey:@"networkInUse"];
    }
}

- (void)decrementingRunningNetworkTransferCount{
    BOOL movingToNotInUse = (self->_runningNetworkTransferCount == 1);
    
    if (movingToNotInUse) {
        [self willChangeValueForKey:@"networkInUse"];
    }
    self->_runningNetworkTransferCount -= 1;
    if (movingToNotInUse) {
        [self didChangeValueForKey:@"networkInUse"];
    }
}

- (void)addOperation:(NSOperation *)operation toQueue:(NSOperationQueue *)queue finishedTarget:(id)target action:(SEL)action{
    if (queue == self.queueForNetworkTransfers) {
        [self performSelectorOnMainThread:@selector(incrementRunningNetworkTransferCount) withObject:nil waitUntilDone:NO];
    }
    
    @synchronized(self){
        CFDictionarySetValue(self->_runningOperationToTragetMap, (__bridge const void *)(operation), (__bridge const void *)(target));
        CFDictionarySetValue(self->_runningOperationToActionMap, (__bridge const void *)(operation), action);
        CFDictionarySetValue(self->_runningOperationToThreadMap, (__bridge const void *)(operation), (__bridge const void *)([NSThread currentThread]));
    }
    
    [operation addObserver:self forKeyPath:@"isFinished" options:0 context:(__bridge void *)(queue)];
    
    [queue addOperation:operation];
}

- (void)addNetworkManagementOperation:(NSOperation *)operation finishedTarget:(id)target action:(SEL)action{
    if ([operation respondsToSelector:@selector(setRunloopThread:)]) {
        if ([(id)operation runloopThread] == nil) {
            [(id)operation setRunloopThread:self.networkRunLoopThread];
        }
    }
    
    [self addOperation:operation toQueue:self.queueForNetworkManagement finishedTarget:target action:action];
}

- (void)addNetworkTransferOperation:(NSOperation *)operation finishedTarget:(id)target action:(SEL)action{
    if ([(id)operation respondsToSelector:@selector(setRunloopThread:)]) {
        if ([(id)operation runloopThread] == nil) {
            [(id)operation setRunloopThread:self.networkRunLoopThread];
        }
    }
    
    [self addOperation:operation toQueue:self.queueForNetworkTransfers finishedTarget:target action:action];
}

- (void)addCPUOperation:(NSOperation *)operation finishedTarget:(id)target action:(SEL)action{
    [self addOperation:operation toQueue:self.queueForCPU finishedTarget:target action:action];
}

- (void)addRunLoopCPUOperation:(NSOperation *)operation finishedTarget:(id)target action:(SEL)action{
    if ([(id)operation respondsToSelector:@selector(setRunloopThread:)]){
        if ([(id)operation runloopThread] == nil) {
            [(id)operation setRunloopThread:self.cpuRunLoopThread];
        }
    }
    
    [self addOperation:operation toQueue:self.queueForCPURunLoopOpearations finishedTarget:target action:action];
}

- (void)addSecondaryRunLoopCPUOperation:(NSOperation *)operation finishedTarget:(id)target action:(SEL)action{
    NSLog(@"Adding Secondary RunLoop Operaion");
    if ([(id)operation respondsToSelector:@selector(setRunloopThread:)]){
        if ([(id)operation runloopThread] == nil) {
            [(id)operation setRunloopThread:self.secondaryUpdateThread];
        }
    }
    NSLog(@"Number Of Operations == %d", self.queueForSecondaryRunLoopOperations.operationCount);
    [self addOperation:operation toQueue:self.queueForSecondaryRunLoopOperations finishedTarget:target action:action];
}

- (void)addUpdateCPURunLoopOperation:(NSOperation *)operation finishedTarget:(id)target action:(SEL)action{
    if ([(id)operation respondsToSelector:@selector(setRunloopThread:)]){
        if ([(id)operation runloopThread] == nil) {
            [(id)operation setRunloopThread:self.updateCPURunLoopThread];
        }
    }
    
    [self addOperation:operation toQueue:self.queueForCPUUpdateOperations finishedTarget:target action:action];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"isFinished"]) {
        NSOperation *operation;
        NSOperationQueue *queue;
        NSThread *thread;
        
        operation = (NSOperation *)object;
        queue = (__bridge NSOperationQueue *)context;
        
        [operation removeObserver:self forKeyPath:@"isFinished"];
        
        @synchronized(self){
            thread = (__bridge NSThread *)CFDictionaryGetValue(self->_runningOperationToThreadMap, (__bridge const void *)(operation));
        }
        
        if (thread != nil) {
            [self performSelector:@selector(operationDone:) onThread:thread withObject:operation waitUntilDone:NO];
            
            if (queue == self.queueForNetworkManagement) {
                [self performSelectorOnMainThread:@selector(decrementingRunningNetworkTransferCount) withObject:nil waitUntilDone:NO];
            }
        }
    }else if (NO){
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (void)operationDone:(NSOperation *)operation{
    id  target;
    SEL action;
    NSThread * thread;
    
    @synchronized(self){
        target = (__bridge id) CFDictionaryGetValue(self->_runningOperationToTragetMap, (__bridge const void *)(operation));
        action = (SEL) CFDictionaryGetValue(self->_runningOperationToActionMap, (__bridge const void *)(operation));
        thread = (__bridge NSThread *) CFDictionaryGetValue(self->_runningOperationToThreadMap, (__bridge const void *)(operation));
        
        if (target != nil) {
            
            CFDictionaryRemoveValue(self->_runningOperationToTragetMap, (__bridge const void *)(operation));
            CFDictionaryRemoveValue(self->_runningOperationToActionMap, (__bridge const void *)(operation));
            CFDictionaryRemoveValue(self->_runningOperationToThreadMap, (__bridge const void *)(operation));
        }
    }
    
    if (target != nil) {
        if (![operation isCancelled]) {
            [target performSelector:action onThread:thread withObject:operation waitUntilDone:NO ];
        }
        target = nil;
    }
}

- (void)cancelOperation:(NSOperation *)operation{
    id  target;
    SEL action;
    NSThread * thread;
    
    if (operation != nil) {
        [operation cancel];
        
        @synchronized(self){
            target = (__bridge id)CFDictionaryGetValue(self->_runningOperationToTragetMap, (__bridge const void *)(operation));
            action = (SEL)CFDictionaryGetValue(self->_runningOperationToActionMap, (__bridge const void *)(operation));
            thread = (__bridge NSThread *) CFDictionaryGetValue(self->_runningOperationToThreadMap, (__bridge const void *)(operation));
            
            assert( (target != nil) == (action != nil) );
            assert( (target != nil) == (thread != nil) );
            if (target != nil) {
                CFDictionaryRemoveValue(self->_runningOperationToTragetMap, (__bridge const void *)(operation));
                CFDictionaryRemoveValue(self->_runningOperationToActionMap, (__bridge const void *)(operation));
                CFDictionaryRemoveValue(self->_runningOperationToThreadMap, (__bridge const void *)(operation));
            }
        }
    }
}
@end
