//
//  NSDate+NSDate_Extensions.m
//  dodgy
//
//  Created by Steve_Sanchez on 9/1/12.
//  Copyright (c) 2012 Apargo. All rights reserved.
//

#import "NSDate+NSDate_Extensions.h"

@implementation NSDate (NSDate_Extensions)


- (NSDictionary *)timeIntervalForDate:(NSDate *)givenDate{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSUInteger unitFlags = NSMonthCalendarUnit | NSWeekCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSDateComponents *components = [calendar components:unitFlags fromDate:givenDate toDate:[NSDate date] options:0];
    
    NSInteger months = [components month];
    NSInteger weeks = [components week];
    NSInteger days = [components day];
    NSInteger hours = [components hour];
    NSInteger minutes = [components minute];
    NSInteger seconds = [components second];
    NSDictionary *retval = [NSDictionary dictionary];
    
    if (months > 0) {
        retval = @{ @"TimeInterval" : @(kTimeIntervalMonths), @"TimeValue" : @(months)};
    }else if (weeks > 0){
        retval = @{@"TimeInterval" : @(kTimeIntervalWeeks), @"TimeValue" : @(weeks)};
    }else if (days > 0){
        retval = @{ @"TimeInterval" : @(kTimeIntervalDays), @"TimeValue" : @(days)};
    }else if (hours){
        retval = @{ @"TimeInterval" : @(kTimeIntervalHours), @"TimeValue" : @(hours)};
    }else if (minutes > 0){
        retval = @{ @"TimeInterval" : @(kTimeIntervalMinutes), @"TimeValue" : @(minutes)};
    }else if (seconds){
        retval = @{ @"TimeInterval" : @(kTimeIntervalSeconds), @"TimeValue" : @(seconds)};
    }
    
    return retval;
}


@end
