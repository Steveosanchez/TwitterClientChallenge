//
//  CPTOperationAndRunLoopManager.h
//  CrossPointMedia
//
//  Created by Steve_Sanchez on 6/22/12.
//  Copyright (c) 2012 Apargo. All rights reserved.
//

#import "CPTOperationsRunLoop.h"

@interface CPTOperationAndRunLoopManager : CPTOperationsRunLoop
@property (nonatomic, unsafe_unretained, readonly) BOOL networkInUse;

+ (CPTOperationAndRunLoopManager *)sharedManager;
- (NSMutableURLRequest *)requestToGetURL:(NSURL *)url;

- (void)addNetworkManagementOperation:(NSOperation *)operation finishedTarget:(id)target action:(SEL)action;
- (void)addNetworkTransferOperation:(NSOperation *)operation finishedTarget:(id)target action:(SEL)action;
- (void)addCPUOperation:(NSOperation *)operation finishedTarget:(id)target action:(SEL)action;
- (void)addRunLoopCPUOperation:(NSOperation *)operation finishedTarget:(id)target action:(SEL)action;
- (void)addUpdateCPURunLoopOperation:(NSOperation *)operation finishedTarget:(id)target action:(SEL)action;
- (void)addSecondaryRunLoopCPUOperation:(NSOperation *)operation finishedTarget:(id)target action:(SEL)action;
- (void)cancelOperation:(NSOperation *)operation;

@end
