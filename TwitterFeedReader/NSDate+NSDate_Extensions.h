//
//  NSDate+NSDate_Extensions.h
//  dodgy
//
//  Created by Steve_Sanchez on 9/1/12.
//  Copyright (c) 2012 Apargo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum TimeIntervalLevels : NSInteger{
    kTimeIntervalSeconds = 0,
    kTimeIntervalMinutes = 1,
    kTimeIntervalHours = 2,
    kTimeIntervalDays = 3,
    kTimeIntervalWeeks = 4,
    kTimeIntervalMonths = 5
    
}TimeIntervalLevels;


@interface NSDate (NSDate_Extensions)


- (NSDictionary *)timeIntervalForDate:(NSDate *)givenDate;
@end
