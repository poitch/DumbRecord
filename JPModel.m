//
//  JPModel.m
//  JPData
//
//  Created by Jerome Poichet on 3/12/10.
//  Copyright 2010 OnLive, Inc.. All rights reserved.
//

#import "JPModel.h"
#import "JPLite.h"
#include <objc/runtime.h> //objc runtime api’s

@interface NSString (Plural)

- (NSString *) plural;

@end

@implementation NSString (Plural)

- (NSString *) plural
{
    return [self stringByAppendingString: @"s"];
}

@end


@interface JPModel (Private)

+ (NSArray *) keys;

@end

@implementation JPModel

- (NSString *) description
{
    NSArray *keys = [[self class] keys];
    int i, n = [keys count];
    NSString *description = [NSString stringWithFormat:@"%@: ", [self class]];
    for (i = 0; i < n; i++) {
        NSString *key = [keys objectAtIndex: i];
        description = [description stringByAppendingFormat: @"%@=%@", key, [self valueForKey: key]];
        if (i < n - 1) {
            description = [description stringByAppendingString: @","];
        }
    }
    return description;
}

// insert model
- (void) insert: (JPLite *) db
{
    NSArray *keys = [[self class] keys];
    NSString *className = NSStringFromClass([self class]);
    NSString *tableName = [[className lowercaseString] plural];
    NSString *idColumnName = [[className lowercaseString] stringByAppendingString: @"_id"];

    NSString *query = [NSString stringWithFormat:@"INSERT INTO %@", tableName];
    int i, n = [keys count];
    
    NSMutableArray *columns = [[NSMutableArray alloc] initWithCapacity: n];
    NSMutableArray *values = [[NSMutableArray alloc] initWithCapacity: n];
    for (i = 0; i < n; i++) {
        NSString *key = [keys objectAtIndex: i];
        id value = [self valueForKey: key];
        if (value != nil && ![value isKindOfClass: [NSNull class]]) {
            [columns addObject: key];
            [values addObject: value];
        }
    }
    
    n = [columns count];
    query = [query stringByAppendingString: @"("];
    for (i = 0; i < n; i++) {
        query = [query stringByAppendingFormat: @"%@", [columns objectAtIndex: i]];
        if (i != n - 1) {
            query = [query stringByAppendingString: @","];
        }
    }
    query = [query stringByAppendingString: @") VALUES ("];
    for (i = 0; i < n; i++) {
        query = [query stringByAppendingFormat: @"'%@'", [values objectAtIndex: i]];
        if (i != n - 1) {
            query = [query stringByAppendingString: @","];
        }
    }
    query = [query stringByAppendingString: @")"];
    

    NSError *error = nil;
    [db query: query withError: &error];
    if (error) {
        NSLog(@"%@", error);
        return;
    }
    
    // We need to update the idColumnName value
    [self setValue: [db lastId] forKey: idColumnName];
}

// update model
- (void) update: (JPLite *) db
{
    NSArray *keys = [[self class] keys];
    NSString *className = NSStringFromClass([self class]);
    NSString *idColumnName = [[className lowercaseString] stringByAppendingString: @"_id"];
    NSString *tableName = [[className lowercaseString] plural];    
    NSString *query = [NSString stringWithFormat:@"UPDATE %@ SET ", tableName];
    int i, n = [keys count];
    
    NSMutableArray *columns = [[NSMutableArray alloc] initWithCapacity: n];
    NSMutableArray *values = [[NSMutableArray alloc] initWithCapacity: n];
    for (i = 0; i < n; i++) {
        NSString *key = [keys objectAtIndex: i];
        id value = [self valueForKey: key];
        if (![key isEqualToString: idColumnName]) {
            [columns addObject: key];
            if (value == nil) {
                [values addObject: [NSNull null]];
            } else {
                [values addObject: value];                
            }
        }
    }
    
    n = [columns count];

    for (i = 0; i < n; i++) {
        if ([[values objectAtIndex: i] isKindOfClass: [NSNull class]]) {
            query = [query stringByAppendingFormat: @"%@ = NULL", [columns objectAtIndex: i]];
        } else {
            query = [query stringByAppendingFormat: @"%@ = '%@'", [columns objectAtIndex: i], [values objectAtIndex: i]];            
        }

        if (i != n - 1) {
            query = [query stringByAppendingString: @","];
        }
    }

    query = [query stringByAppendingFormat: @" WHERE %@ = %@", idColumnName, [self valueForKey: idColumnName]];
    
    //NSLog(@"%@", query);

    NSError *error = nil;
    [db query: query withError: &error];
    if (error) {
        NSLog(@"%@", error);
    }

}

// delete model from database
- (void) delete: (JPLite *) db
{
    NSString *className = NSStringFromClass([self class]);
    NSString *idColumnName = [[className lowercaseString] stringByAppendingString: @"_id"];
    NSString *tableName = [[className lowercaseString] plural];    
    NSString *query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = %@", tableName, idColumnName, [self valueForKey: idColumnName]];
    //NSLog(@"%@", query);
    NSError *error = nil;
    [db query: query withError: &error];
    if (error) {
        NSLog(@"%@", error);
    }
    
}

// Search for objects in the database
+ (NSArray *) findWhere: (NSDictionary *) clauses inDB: (JPLite *)db
{
    Class class = [self class];
    NSString *className = NSStringFromClass(class);
    NSString *tableName = [[className lowercaseString] plural];
    NSString *query;
    NSError *error = nil;
    NSArray *rows;
    NSMutableArray *results;
    int i, n;
    
    query = [NSString stringWithFormat: @"SELECT * FROM %@", tableName];
    if (clauses) {
        NSMutableArray *parts = [[NSMutableArray alloc] init];
        NSEnumerator *enumerator = [clauses keyEnumerator];
        NSString *key;
        while ((key = [enumerator nextObject])) {
            id value = [clauses objectForKey: key];

            if ([value isKindOfClass: [NSNull class]]) {
                [parts addObject:[NSString stringWithFormat: @"%@ IS NULL", key]];
            } else if ([value isKindOfClass: [NSDate class]]) {
                // Unix timestamp
                [parts addObject:[NSString stringWithFormat: @"%@ = %d", key, [(NSDate *)value timeIntervalSince1970]]];
            } else {
                [parts addObject:[NSString stringWithFormat: @"%@ = '%@'", key, (NSString *)value]];
            }
        }
        
        query = [query stringByAppendingString: @" WHERE "];
        n = [parts count];
        for (i = 0; i < n; i++) {
            query = [query stringByAppendingString: [parts objectAtIndex: i]];
            if (i < n - 1) {
                query = [query stringByAppendingString: @" AND "];
            }
        }
    }
    
    //NSLog(@"%@", query);
    
    rows = [db query: query withError: &error];
    if (error) {
        NSLog(@"%@", error);
        return nil;
    }
    
    
    n = [rows count];
    results = [[NSMutableArray alloc] initWithCapacity: n];
    for (i = 0; i < n; i++) {
        NSDictionary *row = [rows objectAtIndex: i];
        NSEnumerator *enumerator = [row keyEnumerator];
        NSString *key;

        id obj = [[class alloc] init];
        
        while ((key = [enumerator nextObject])) {
            @try {
                if (![[row objectForKey: key] isKindOfClass: [NSNull class]]) {
                    [obj setValue: [row objectForKey: key] forKey: key];                                    
                }
            }
            @catch (NSException *e) {
                NSLog(@"%@", e);
            }

        }
        
        [results addObject: obj];
    }
    //NSLog(@"%@", results);
    
    return results;
}

@end

@implementation JPModel (Private)

// Columns
+ (NSArray *) keys
{
    unsigned int outCount = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    int i;
    NSMutableArray *keys = [[NSMutableArray alloc] initWithCapacity: outCount];
    for(i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName) {
            NSString *propertyName = [NSString stringWithCString: propName encoding: NSUTF8StringEncoding];
            [keys addObject: propertyName];
        }
    }
    free(properties);
    return keys;
}

@end
