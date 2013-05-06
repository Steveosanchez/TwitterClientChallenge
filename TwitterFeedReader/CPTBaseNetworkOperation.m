//
//  CPTBaseNetworkOperation.m
//  CrossPointMedia
//
//  Created by Steve_Sanchez on 6/21/12.
//  Copyright (c) 2012 Apargo. All rights reserved.
//

#import "CPTBaseNetworkOperation.h"

@interface CPTBaseNetworkOperation (){
    
    NSURLRequest        *_request;
    NSURL               *_URL;
    NSIndexSet          *_acceptableStatusCodes;
    NSSet               *_acceptableContentTypes;
    NSOutputStream      *_responseOutputStream;
    NSUInteger          _defaultResponseSize;
    NSUInteger          _maximumResponseSize;
    NSURLRequest        *_lastRequest;
    NSHTTPURLResponse   *_lastResponse;
    NSData              *_responseBody;
    NSMutableData       *_dataAccumulator;
    BOOL                _firstData;
    NSURLConnection     *_connection;
}

@property (copy, readwrite) NSURLRequest *lastRequest;
@property (copy, readwrite) NSHTTPURLResponse *lastResponse;
@property (strong, readwrite) NSURLConnection *connection;
@property (unsafe_unretained, readwrite) BOOL firstData;
@property (strong, readwrite) NSMutableData *dataAccumulator;
@end

@implementation CPTBaseNetworkOperation

- (id)initWithRequest:(NSURLRequest *)request{
    assert(request != nil);
    assert([request URL] != nil);
    self = [super init];
    if (self) {
#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
        static const NSUInteger kPlatformReductionFactor = 4;
#else
        static const NSUInteger kPlatformReductionFactor = 1;
#endif
        
        self->_request = [request copy];
        self->_defaultResponseSize = 1 * 1024 * 1024 / kPlatformReductionFactor;
        self->_maximumResponseSize = 4 * 1024 * 1024 / kPlatformReductionFactor * 1000000000;
        self->_firstData = YES;
    }
    return self;
}

- (id)initWithURL:(NSURL *)url{
    assert(url != nil);
    return [self initWithRequest:[NSURLRequest requestWithURL:url]];
}

+ (BOOL)automaticallyNotifiesObserversOfAcceptableStatusCodes{
    return NO;
}

- (NSIndexSet *)acceptableStatusCodes{
    return self->_acceptableStatusCodes;
}

- (void)setAcceptableStatusCodes:(NSIndexSet *)newValue{
    if (self.state != kOperationRunLoopStateInitiated) {
        assert(NO);
    }else{
        if (newValue != self->_acceptableStatusCodes) {
            [self willChangeValueForKey:@"acceptableStatusCodes"];
            self->_acceptableStatusCodes = newValue;
            [self didChangeValueForKey:@"acceptableStatusCodes"];
        }
    }
}

+ (BOOL)automaticallyNotifiesObserversOfAcceptableContentTypes{
    return NO;
}

- (NSSet *)acceptableContentTypes{
    return self->_acceptableContentTypes;
}

- (void)setAcceptableContentTypes:(NSSet *)newValue{
    if (self.state != kOperationRunLoopStateInitiated) {
        assert(NO);
    }else{
        if (newValue != self->_acceptableContentTypes) {
            [self willChangeValueForKey:@"acceptableContentTypes"];
            self->_acceptableContentTypes = newValue;
            [self didChangeValueForKey:@"acceptableContentTypes"];
        }
    }
}

+ (BOOL)automaticallyNotifiesObserversOfResponseOutputStream{
    return NO;
}

- (NSOutputStream *)responseOutputStream{
    return self->_responseOutputStream;
}

- (void)setResponseOutputStream:(NSOutputStream *)newValue{
    if (self.state != kOperationRunLoopStateInitiated) {
        assert(NO);
    }else{
        if (newValue != self->_responseOutputStream) {
            [self willChangeValueForKey:@"responseOutputStream"];
            self->_responseOutputStream = newValue;
            [self didChangeValueForKey:@"responseOutputStream"];
        }
    }
}

+ (BOOL)automaticallyNotifiesObserversOfDefaultResponseSize{
    return NO;
}
- (NSUInteger)defaultResponseSize{
    return self->_defaultResponseSize;
}

- (void)setDefaultResponseSize:(NSUInteger)newValue{
    if (self.dataAccumulator != nil) {
        assert(NO);
    }else{
        if (newValue != self->_defaultResponseSize) {
            [self willChangeValueForKey:@"defaultResponseSize"];
            self->_defaultResponseSize = newValue;
            [self didChangeValueForKey:@"defaultResponseSize"];
        }
    }
}

+ (BOOL)automaticallyNotifiesObserversOfMaximumResponseSize{
    return NO;
}

- (NSUInteger)maximumResponseSize{
    return self->_maximumResponseSize;
}

- (void)setMaximumResponseSize:(NSUInteger)newValue{
    if (self.dataAccumulator != nil) {
        assert(NO);
    }else{
        if (newValue != self->_maximumResponseSize) {
            [self willChangeValueForKey:@"maximumResponseSize"];
            self->_maximumResponseSize = newValue;
            [self didChangeValueForKey:@"maximumResponseSize"];
        }
    }
}

- (NSURL *)URL{
    return [self.request URL];
}

- (BOOL)isStatusCodeAcceptable{
    NSIndexSet *acceptableStatusCodes;
    NSInteger statusCode = 0;
    
    assert(self.lastResponse != nil);
    
    acceptableStatusCodes = self.acceptableStatusCodes;
    
    if (acceptableStatusCodes == nil) {
        acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    }
    
    assert(acceptableStatusCodes != nil);
    
    statusCode = [self.lastResponse statusCode];
    
    return [acceptableStatusCodes containsIndex:statusCode];
}

- (BOOL)isContentTypeAcceptable{
    NSString *contentType = nil;
    
    assert(self.lastResponse != nil);
    
    contentType = [self.lastResponse MIMEType];
    
    return (self.acceptableContentTypes == nil) || ((contentType != nil) && [self.acceptableContentTypes containsObject:contentType]);
}

- (void)finishWithError:(NSError *)error{
    [super finishWithError:error];
}

- (void)operationDidStart{
    self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
    
    for (NSString *mode in self.actualRunLoopModes) {
        [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
    }
    
    [self.connection start];
}

- (void)operationWillFinish{
    [self.connection cancel];
    
    if (self.responseOutputStream != nil) {
        [self.responseOutputStream close];
    }
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response{
    self.lastResponse = (NSHTTPURLResponse *)response;
    self.lastRequest = request;
    //NSLog(@"error Code : %d", self.lastResponse.statusCode);
    //NSLog(@"Last Response = %@",self.lastResponse.allHeaderFields);
    //NSLog(@"Last Request == %@", self.lastRequest);
    //NSLog(@"Last RequestHeaders == %@", self.lastRequest.allHTTPHeaderFields);
    //NSLog(@"Last Connection == %@", connection);
    return self.lastRequest;
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    self.lastResponse = (NSHTTPURLResponse *)response;
    //NSLog(@"error Code : %d", self.lastResponse.statusCode);
    //NSLog(@"Last Response = %@",self.lastResponse.allHeaderFields);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    BOOL success = YES;
    
    //NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //NSLog(@"Data From Network :::: %@", dataString);
    //NSLog(@"NetworkConnection == %@", connection.originalRequest);
    
    if (self.firstData) {
        if ((self.responseOutputStream == nil) || !self.isStatusCodeAcceptable) {
            long long length = 0;
            length = [self.lastResponse expectedContentLength];
            if (length == NSURLResponseUnknownLength) {
                length = self.defaultResponseSize;
            }
            if (length <= (long long) self.maximumResponseSize) {
                self.dataAccumulator = [NSMutableData dataWithCapacity:(NSUInteger)length];
            }else{
                [self finishWithError:[NSError errorWithDomain:kBaseNetworkOperationErrorDomain code:kBaseNetworkOperationErrorResponseTooLarge userInfo:nil]];
                success = NO;
            }
        }
        
        if (success) {
            if (self.dataAccumulator == nil) {
                [self.responseOutputStream open];
            }
        }
        self.firstData = NO;
    }
    
    if (success) {
        if (self.dataAccumulator != nil) {
            if (([self.dataAccumulator length] + [data length]) <= self.maximumResponseSize) {
                [self.dataAccumulator appendData:data];
            }else{
                [self finishWithError:[NSError errorWithDomain:kBaseNetworkOperationErrorDomain code:kBaseNetworkOperationErrorResponseTooLarge userInfo:nil]];
            }
        }else{
            NSUInteger dataOffset = 0;
            NSUInteger dataLength = 0;
            const uint8_t *dataPtr;
            NSError *error = nil;
            NSInteger bytesWritten = 0;
            
            assert(self.responseOutputStream != nil);
            
            dataLength = [data length];
            dataPtr = [data bytes];
            
            do{
                if (dataOffset == dataLength) {
                    break;
                }
                
                bytesWritten = [self.responseOutputStream write:&dataPtr[dataOffset] maxLength:dataLength - dataOffset];
                if (bytesWritten <= 0 ) {
                    error = [self.responseOutputStream streamError];
                    if (error == nil) {
                        error = [NSError errorWithDomain:kBaseNetworkOperationErrorDomain code:kBaseNetworkOperationErrorOnOutputStreat userInfo:nil];
                    }
                    break;
                }else{
                    dataOffset += bytesWritten;
                }
            }while (YES);
            if (error != nil) {
                ///
            }
        }
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    assert(self.isActualRunLoopThread);
    assert(connection == self.connection);
    assert(self.lastResponse != nil);
    assert(self->_responseBody == nil);
    
    self->_responseBody = self->_dataAccumulator;
    self->_dataAccumulator = nil;
    
    if (self->_responseBody == nil) {
        self->_responseBody = [[NSData alloc] init];
        assert(self->_responseBody != nil);
    }
    
    if (!self.isStatusCodeAcceptable) {
        [self finishWithError:[NSError errorWithDomain:kBaseNetworkOperationErrorDomain code:self.lastResponse.statusCode userInfo:nil]];
    }else if (! self.isContentTypeAcceptable){
        [self finishWithError:[NSError errorWithDomain:kBaseNetworkOperationErrorDomain code:kBaseNetworkOperationErrorBadContentType userInfo:nil]];
    }else{
        [self finishWithError:nil];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"Connection Error for Connection == %@  Error == %@", connection, error);
    [self finishWithError:error];
}
@end

NSString * kBaseNetworkOperationErrorDomain = @"kBaseNetworkOperationErrorDomain";
