//
//  Track.m
//  DumbRecord
//
//  Created by Jerome Poichet on 3/16/10.
//  Copyright 2010 Jerome Poichet. All rights reserved.
//

#import "Track.h"


@implementation Track

@synthesize track_id, name, duration, someFloat, someUnique, someBool, createdOn;

+ (id) defaultValueForColumn: (NSString *) columnName
{
    if ([columnName isEqualToString: @"createdOn"]) {
        return [NSDate date];
    }
    return [DRModel defaultValueForColumn: columnName];
}

+ (BOOL) shouldColumnBeUnique: (NSString *) columnName
{
    if ([columnName isEqualToString: @"someUnique"]) {
        return YES;
    }
    return [DRModel shouldColumnBeUnique: columnName];
}


+ (NSArray *) indexes
{
    return [NSArray arrayWithObjects: @"name", [NSArray arrayWithObjects: @"someFloat", @"someBool", nil], nil];
}

@end
