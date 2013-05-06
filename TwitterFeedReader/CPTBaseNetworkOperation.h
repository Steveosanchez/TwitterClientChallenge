//
//  CPTBaseNetworkOperation.h
//  CrossPointMedia
//
//  Created by Steve_Sanchez on 6/21/12.
//  Copyright (c) 2012 Apargo. All rights reserved.
//

#import "CPTOperationsRunLoop.h"

@interface CPTBaseNetworkOperation : CPTOperationsRunLoop <NSURLConnectionDelegate>

@property (copy, readonly) NSURLRequest             *request;
@property (copy, readonly) NSURL                    *URL;
@property (copy, readwrite) NSIndexSet              *acceptableStatusCodes;
@property (copy, readwrite) NSSet                   *acceptableContentTypes;
@property (strong, readwrite) NSOutputStream        *responseOutputStream;
@property (unsafe_unretained, readwrite) NSUInteger defaultResponseSize;
@property (unsafe_unretained, readwrite) NSUInteger maximumResponseSize;
@property (copy, readonly) NSURLRequest             *lastRequest;
@property (copy, readonly) NSHTTPURLResponse        *lastResponse;
@property (copy, readonly) NSData                   *responseBody;

- (id)initWithRequest:(NSURLRequest *)request;
- (id)initWithURL:(NSURL *)url;

@end

extern NSString * kBaseNetworkOperationErrorDomain;

enum {
    kBaseNetworkOperationErrorResponseTooLarge = -1,
    kBaseNetworkOperationErrorOnOutputStreat = -2,
    kBaseNetworkOperationErrorBadContentType = -3
};
