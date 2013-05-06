//
//  CPTOperationsRunLoop.m
//  CrossPointMedia
//
//  Created by Steve_Sanchez on 6/21/12.
//  Copyright (c) 2012 Apargo. All rights reserved.
//

#import "CPTOperationsRunLoop.h"


@interface CPTOperationsRunLoop (){
    NSThread                *_runloopThread;
    NSSet                   *_runLoopModes;
    NSError                 *_error;
    OperationsRunLoopState  _state;
    NSThread                *_actualRunLoopThread;
    BOOL                    isAcutalRunLoopThread;
    NSSet                   *actualRunLoopModes;
}

@property (unsafe_unretained,readwrite) OperationsRunLoopState state;
@property (copy,readwrite) NSError *error;

@end


@implementation CPTOperationsRunLoop

- (id)init{
    
    self = [super init];
    if (self) {
        assert(self->_state == kOperationRunLoopStateInitiated);
    }
    return self;
}

- (NSThread *)actualRunLoopThread{
    NSThread *result;
    result = self.runloopThread;
    if (result == nil) {
        result = [NSThread mainThread];
    }
    return result;
}

- (BOOL)isActualRunLoopThread{
    return [[NSThread currentThread] isEqual:self.actualRunLoopThread];
}

- (NSSet *)actualRunLoopModes{
    NSSet *result;
    result = self.runLoopModes;
    if ((result == nil) || ([result count] == 0)) {
        result = [NSSet setWithObject:NSDefaultRunLoopMode];
    }
    return result;
}

- (OperationsRunLoopState)state{
    return self->_state;
}

- (void)setState:(OperationsRunLoopState)newState{
    @synchronized(self){
        OperationsRunLoopState oldState;
        assert(newState > self->_state);
        assert(newState != kOperationRunLoopStateFinished || self.isActualRunLoopThread);
        oldState = self->_state;
        
        if ((newState == kOperationRunLoopStateExecuting) || (oldState == kOperationRunLoopStateExecuting)) {
            [self willChangeValueForKey:@"isExecuting"];
        }
        if (newState == kOperationRunLoopStateFinished) {
            [self willChangeValueForKey:@"isFinished"];
        }
        self->_state = newState;
        
        if (newState == kOperationRunLoopStateFinished) {
            [self didChangeValueForKey:@"isFinished"];
        }
        
        if ((newState == kOperationRunLoopStateExecuting) || (oldState == kOperationRunLoopStateExecuting)) {
            [self didChangeValueForKey:@"isExecuting"];
        }
    }
}

- (void)startOnRunLoopThread{
    assert(self.isActualRunLoopThread);
    assert(self.state == kOperationRunLoopStateExecuting);
    
    if ([self isCancelled]) {
        [self finishWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
    }else{
        [self operationDidStart];
    }
}

- (void)cancelOnRunLoopThread{
    assert(self.isActualRunLoopThread);
    assert(self.state == kOperationRunLoopStateExecuting);
    
    if ([self isCancelled]) {
        [self finishWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
    }
}


- (void)finishWithError:(NSError *)error{
        //assert(self.isActualRunLoopThread);
    if (self.error == nil) {
        self.error = error;
    }
    [self operationWillFinish];
    self.state = kOperationRunLoopStateFinished;
}

- (void)operationDidStart{
    assert(self.isActualRunLoopThread);
}

- (void)operationWillFinish{
        //assert(self.isActualRunLoopThread);
}

- (BOOL)isConcurrent{
    return YES;
}

- (BOOL)isExecuting{
    return self.state == kOperationRunLoopStateExecuting;
}

- (BOOL)isFinished{
    return self.state == kOperationRunLoopStateFinished;
}

- (void)start{
    assert(self.state == kOperationRunLoopStateInitiated);
    self.state = kOperationRunLoopStateExecuting;
    
    [self performSelector:@selector(startOnRunLoopThread) onThread:self.actualRunLoopThread withObject:nil waitUntilDone:NO modes:[self.actualRunLoopModes allObjects]];
}

- (void)cancel{
    BOOL runCancelOnRunLoopThread;
    BOOL oldValue;
    
    @synchronized(self){
        oldValue = [self isCancelled];
        [super cancel];
        runCancelOnRunLoopThread = ! oldValue && self.state == kOperationRunLoopStateExecuting;
    }
    
    if (runCancelOnRunLoopThread) {
        [self performSelector:@selector(cancelOnRunLoopThread) onThread:self.actualRunLoopThread withObject:nil waitUntilDone:YES modes:[self.actualRunLoopModes allObjects]];
    }
}

@end
