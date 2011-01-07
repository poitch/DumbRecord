//
//  DRModel.m
//  DumbRecord
//
//  Created by Jerome Poichet on 3/12/10.
//  Copyright 2010 Jerome Poichet. All rights reserved.
//

#import "DRModel.h"
#import "DRLite.h"
#include <objc/runtime.h> //objc runtime api’s
#import "NSStringAdditions.h"

@interface DRModel (Private)

+ (NSArray *) keys;
+ (NSDictionary *) keyAndTypes;

@end

@implementation DRModel

+ (NSArray *) indexes
{
    return nil;
}

+ (BOOL) shouldColumnBeUnique: (NSString *) columnName
{
    return NO;
}

+ (id) defaultValueForColumn: (NSString *) columnName
{
    return nil;
}

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
- (void) insert: (DRLite *) db
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
        if (![key isEqualToString: idColumnName]) {
            id value = [self valueForKey: key];
            id defaultValue = [[self class] defaultValueForColumn: key];
            if (value != nil && ![value isKindOfClass: [NSNull class]]) {
                [columns addObject: key];
                if ([value isKindOfClass: [NSDate class]]) {
                    [values addObject: [NSNumber numberWithInt: [value timeIntervalSince1970]]];
                } else {
                    [values addObject: value];                    
                }
            } else if (defaultValue != nil && ![defaultValue isKindOfClass: [NSNull class]]) {
                [columns addObject: key];
                if ([defaultValue isKindOfClass: [NSDate class]]) {
                    [values addObject: [NSNumber numberWithInt: [defaultValue timeIntervalSince1970]]];
                } else {
                    [values addObject: defaultValue];                    
                }
            }
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
    
    //NSLog(@"%@", query);
    [columns release];
    [values release];
    
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
- (void) update: (DRLite *) db
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
        id defaultValue = [[self class] defaultValueForColumn: key];

        if (![key isEqualToString: idColumnName]) {
            if (value == nil && defaultValue != nil) {
                
            } else {
                [columns addObject: key];
                if (value == nil) {
                    [values addObject: [NSNull null]];
                } else {
                    [values addObject: value];                
                }                
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
    
    [columns release];
    [values release];
    //NSLog(@"%@", query);

    NSError *error = nil;
    [db query: query withError: &error];
    if (error) {
        NSLog(@"%@", error);
    }

}

// delete model from database
- (void) delete: (DRLite *) db
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

+ (id) loadRow: (NSDictionary *) row intoModel: (Class) class
{
    NSEnumerator *enumerator = [row keyEnumerator];
    NSString *key;

    NSDictionary *types = [class keyAndTypes];
    id obj = [[[class alloc] init] autorelease];
    
    while ((key = [enumerator nextObject])) {
        @try {
            // If destination is NSDate then convert from integer to nsdate
            if (![[row objectForKey: key] isKindOfClass: [NSNull class]]) {
                if ([[types objectForKey: key] isEqualToString: @"NSDate"]) {
                    [obj setValue: [NSDate dateWithTimeIntervalSince1970: [[row objectForKey: key] intValue]] forKey: key];
                } else {
                    [obj setValue: [row objectForKey: key] forKey: key];
                }
            }
        }
        @catch (NSException *e) {
            NSLog(@"%@", e);
        }
        
    }
    
    return obj;
    
}

+ (id) getInstance: (int) instanceId inDB: (DRLite *) db
{
    Class class = [self class];
    NSString *className = NSStringFromClass(class);
    NSString *idColumnName = [[className lowercaseString] stringByAppendingString: @"_id"];
    NSString *tableName = [[className lowercaseString] plural];    
    NSString *query = [NSString stringWithFormat: @"SELECT * FROM %@ WHERE %@ = %d", tableName, idColumnName, instanceId];
    NSError *error = nil;
    NSArray *rows;

    rows = [db query: query withError: &error];
    if (error) {
        NSLog(@"%@", error);
        return nil;
    }
    
    NSDictionary *row = [rows objectAtIndex: 0];
    return [DRModel loadRow: row intoModel: class];
}

// Search for objects in the database
+ (NSArray *) findWhere: (NSDictionary *) clauses inDB: (DRLite *)db
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
        
        [parts release];
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
        id obj = [DRModel loadRow: row intoModel: class];
        [results addObject: obj];
    }
    //NSLog(@"%@", results);
    
    return [results autorelease];
}

@end

@implementation DRModel (Private)

// Columns and their types
+ (NSDictionary *) keyAndTypes
{
    unsigned int outCount = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    int i;
    NSMutableDictionary *keys = [[[NSMutableDictionary alloc] initWithCapacity: outCount] autorelease];
    for(i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName) {
            NSString *propertyName = [NSString stringWithCString: propName encoding: NSUTF8StringEncoding];
            NSString *attr = [NSString stringWithCString: property_getAttributes(property)
                                                encoding: NSASCIIStringEncoding];
            
            NSArray *chunks = [attr componentsSeparatedByString: @","];
            NSString *type = [chunks objectAtIndex: 0];
            if ([[type substringWithRange: NSMakeRange(1, 1)] isEqualToString: @"@"]) {
                type = [type substringWithRange: NSMakeRange(3, [type length] - 4)];
            } else {
                // Primitive type
                type = [type substringFromIndex: 1];
            }
            
            NSDictionary *typeMap = [NSDictionary dictionaryWithObjectsAndKeys: 
                                     @"int", @"i",
                                     @"int", @"I",
                                     @"float", @"f",
                                     @"long", @"l",
                                     @"short", @"s",
                                     @"BOOL", @"c",
                                     @"NSNumber", @"NSNumber",
                                     @"NSString", @"NSString",
                                     @"NSData", @"NSData",
                                     @"NSDate", @"NSDate",
                                     nil];
            [keys setObject: [typeMap objectForKey: type] forKey: propertyName];
        }
    }
    free(properties);
    return keys;
}

// Columns
+ (NSArray *) keys
{
    unsigned int outCount = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    int i;
    NSMutableArray *keys = [[[NSMutableArray alloc] initWithCapacity: outCount] autorelease];
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
