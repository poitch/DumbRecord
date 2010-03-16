//
//  NSStringAdditions.m
//  DRecord
//
//  Created by Jerome Poichet on 3/16/10.
//  Copyright 2010 Jerome Poichet. All rights reserved.
//

#import "NSStringAdditions.h"


@implementation NSString (Plural)

- (NSString *) plural
{
    return [self stringByAppendingString: @"s"];
}

@end
