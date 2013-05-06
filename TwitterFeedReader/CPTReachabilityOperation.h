//
//  CPTReachabilityOperation.h
//  CrossPointMedia
//
//  Created by Steve_Sanchez on 6/21/12.
//  Copyright (c) 2012 Apargo. All rights reserved.
//

#import "CPTOperationsRunLoop.h"
#import <SystemConfiguration/SystemConfiguration.h>

@interface CPTReachabilityOperation : CPTOperationsRunLoop
@property (copy, readonly) NSString *hostName;
@property (unsafe_unretained, readwrite) NSUInteger flagsTargetMask;
@property (unsafe_unretained, readwrite) NSUInteger flagsTargetValue;
@property (unsafe_unretained, readonly) NSUInteger flags;

- (id)initWithHostName:(NSString *)hostName;


@end
