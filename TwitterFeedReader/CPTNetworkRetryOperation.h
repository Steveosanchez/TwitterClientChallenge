//
//  CPTNetworkRetryOperation.h
//  CrossPointMedia
//
//  Created by Steve_Sanchez on 6/21/12.
//  Copyright (c) 2012 Apargo. All rights reserved.
//

#import "CPTOperationsRunLoop.h"
#import "CPTBaseNetworkOperation.h"
#import "CPTReachabilityOperation.h"

typedef enum NetworkRetryOperationState : NSUInteger{
    kNetworkOperationStateNotStarted,
    kNetworkOperationStateGetting,
    kNetworkOperationStateWaitingToRetry,
    kNetworkOperationStateRetrying,
    kNetworkOperationStateFinished
} NetworkRetryOperationState;

@interface CPTNetworkRetryOperation : CPTOperationsRunLoop

@property (copy, readonly) NSURLRequest                                 *request;
@property (copy, readwrite) NSSet                                       *acceptableContentTypes;
@property (strong, readwrite) NSString                                  *responseFilePath;
@property (unsafe_unretained, readonly) NetworkRetryOperationState      retryState;
@property (unsafe_unretained, readonly) NetworkRetryOperationState      retryClientState;
@property (unsafe_unretained, readonly) BOOL                            hasHadRetryableFailure;
@property (unsafe_unretained, readonly) NSUInteger                      retryCount;
@property (copy, readonly) NSString                                     *responseMIMEType;
@property (copy, readonly) NSData                                       *responseContent;
@property (unsafe_unretained, readonly) BOOL                            isNetworkReachable;

- (id)initWithRequest:(NSURLRequest*)request;

@end
