//
//  DRecord.m
//  DRecord
//
//  Created by Jerome Poichet on 3/16/10.
//  Copyright 2010 Jerome Poichet. All rights reserved.
//

#import "DRecord.h"
#import "NSStringAdditions.h"
#include <objc/runtime.h> //objc runtime api’s

@implementation DRecord

+ (void) setup: (NSString *) database
{
    [DRecord setup: database withModels: nil];
}

+ (void) setup: (NSString *) database withModels: (NSArray *)models
{
    JPLite *db = [[JPLite alloc] initWithDatabase: database];

    if ([models count] == 0) {
        return;
    }
    
    // Get current list of tables
    NSArray *rows = nil;
    NSError *error = nil;
    NSMutableArray *tables = [[NSMutableArray alloc] init];
    int i, n;
    
    rows = [db query: @"SELECT name FROM sqlite_master WHERE type='table' ORDER BY name" withError: &error];
    n = [rows count];
    
    for (i = 0; i < n; i++) {
        [tables addObject: [[rows objectAtIndex: i] objectForKey: @"name"]];
    }
    
    // Do we have all tables?
    n = [models count];
    for (i = 0; i < n; i++) {
        NSString *model = [models objectAtIndex: i];
        NSString *table_name = [[model lowercaseString] plural];
        NSLog(@"%@ %@", model, table_name);
        if ([tables containsObject: table_name]) {
            // Table exists already, figure out the differences
        } else {
            // New model, create table
            
            id modelClass = objc_getClass([model cStringUsingEncoding: NSASCIIStringEncoding]);
            unsigned int outCount, i;
            objc_property_t *properties = class_copyPropertyList(modelClass, &outCount);
            for (i = 0; i < outCount; i++) {
                objc_property_t property = properties[i];
                NSLog(@"%s %s", property_getName(property), property_getAttributes(property));
            }
            
            
        }
    }

}

@end
