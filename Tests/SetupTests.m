/*
 *  setup.m
 *  DRecord
 *
 *  Created by Jerome Poichet on 3/16/10.
 *  Copyright 2010 Jerome Poichet. All rights reserved.
 *
 */

#import "SetupTests.h"

#import "Track.h"

@implementation SetupTests

- (void) testCreate
{
    [DRecord setup: @"testCreate.sql" withModels: [NSArray arrayWithObjects: @"Track", nil]];
    STAssertTrue(YES, @"This should be yes");
}

@end