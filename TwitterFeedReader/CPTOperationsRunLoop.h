//
//  CPTOperationsRunLoop.h
//  CrossPointMedia
//
//  Created by Steve_Sanchez on 6/21/12.
//  Copyright (c) 2012 Apargo. All rights reserved.
//

#import <Foundation/Foundation.h>


enum OperationsRunLoopState {
    kOperationRunLoopStateInitiated,
    kOperationRunLoopStateExecuting,
    kOperationRunLoopStateFinished
};
typedef enum OperationsRunLoopState OperationsRunLoopState;


@interface CPTOperationsRunLoop : NSOperation

@property (readwrite, strong) NSThread                          *runloopThread;
@property (copy, readwrite) NSSet                               *runLoopModes;
@property (copy, readonly) NSError                              *error;
@property (readonly, unsafe_unretained) OperationsRunLoopState  state;
@property (readonly, strong) NSThread                           *actualRunLoopThread;
@property (readonly, unsafe_unretained) BOOL                    isActualRunLoopThread;
@property (copy, readonly) NSSet                                *actualRunLoopModes;

@end


@interface CPTOperationsRunLoop (subClassSupport)
- (void)operationDidStart;
- (void)operationWillFinish;
- (void)finishWithError:(NSError *)error;

@end