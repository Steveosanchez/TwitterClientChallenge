//
//  CPTReachabilityOperation.m
//  CrossPointMedia
//
//  Created by Steve_Sanchez on 6/21/12.
//  Copyright (c) 2012 Apargo. All rights reserved.
//

#import "CPTReachabilityOperation.h"
@interface CPTReachabilityOperation (){
    
    NSString *_hostName;
    NSUInteger _flagsTargetMask;
    NSUInteger _flagsTargetValue;
    NSUInteger _flags;
    SCNetworkReachabilityRef _ref;
}
@property (unsafe_unretained, readwrite) NSUInteger flags;

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info);

- (void)reachabilityFlags:(NSUInteger)newValue;

@end

@implementation CPTReachabilityOperation

- (id)initWithHostName:(NSString *)hostName{
    self = [super init];
    if (self) {
        self->_hostName = [hostName copy];
        self->_flagsTargetMask = kSCNetworkReachabilityFlagsReachable | kSCNetworkReachabilityFlagsInterventionRequired | kSCNetworkReachabilityFlagsConnectionRequired;
        self->_flagsTargetValue = kSCNetworkReachabilityFlagsReachable;
    }
    return self;
}

- (void)operationDidStart{
    Boolean success;
    SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    
    self->_ref = SCNetworkReachabilityCreateWithName(NULL, [self.hostName UTF8String]);
    success = SCNetworkReachabilitySetCallback(self->_ref, ReachabilityCallback, &context);
    assert(success);
    
    for (NSString *mode in self.actualRunLoopModes) {
        success = SCNetworkReachabilityScheduleWithRunLoop(self->_ref, CFRunLoopGetCurrent(), (__bridge CFStringRef)mode);
        assert(success);
    }
}

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void * info){
    CPTReachabilityOperation *obj = (__bridge CPTReachabilityOperation *)info;
    [obj reachabilityFlags:flags];
}

- (void)reachabilityFlags:(NSUInteger)newValue{
    
    NSLog(@"Reachability Flag Status: %c%c %c%c%c%c%c%c%c\n",
          (newValue & kSCNetworkReachabilityFlagsIsWWAN)				  ? 'W' : '-',
          (newValue & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
          
          (newValue & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
          (newValue & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
          (newValue & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
          (newValue & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
          (newValue & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
          (newValue & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
          (newValue & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-'
          );
    self.flags = newValue;
    if ((self.flags & self.flagsTargetMask) == self.flagsTargetValue) {
        [self finishWithError:nil];
    }
}

- (void)operationWillFinish{
    Boolean success;
    if (self->_ref != nil) {
        for (NSString *mode in self.actualRunLoopModes) {
            success = SCNetworkReachabilityUnscheduleFromRunLoop(self->_ref, CFRunLoopGetCurrent(), (__bridge CFStringRef)mode);
            assert(success);
        }
        
        success = SCNetworkReachabilitySetCallback(self->_ref, NULL, NULL);
        assert(success);
        CFRelease(self->_ref);
        self->_ref = NULL;
    }
}
@end
