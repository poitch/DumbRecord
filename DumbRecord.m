//
//  DumbRecord.m
//  DumbRecord
//
//  Created by Jerome Poichet on 3/16/10.
//  Copyright 2010 Jerome Poichet. All rights reserved.
//

#import "DumbRecord.h"
#import "NSStringAdditions.h"
#include <objc/runtime.h> //objc runtime api’s

@implementation DumbRecord

+ (DRLite *) setup: (NSString *) database
{
    return [DumbRecord setup: database withModels: nil];
}

+ (DRLite *) setup: (NSString *) database withModels: (NSArray *)models
{
    DRLite *db = [[[DRLite alloc] initWithDatabase: database] autorelease];

    if ([models count] == 0) {
        return db;
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
        NSString *id_column_name = [[model lowercaseString] stringByAppendingString: @"_id"];
        
        
        //NSLog(@"%@ %@ %@", model, table_name, id_column_name);
        if ([tables containsObject: table_name]) {
            // Table exists already, figure out the differences
        } else {
            // New model, create table
            NSMutableDictionary *columns = [[NSMutableDictionary alloc] init];
            
            [columns setObject: @"INTEGER PRIMARY KEY" forKey: id_column_name];

            Class class = NSClassFromString(model);            
            id modelClass = objc_getClass([model cStringUsingEncoding: NSASCIIStringEncoding]);
            unsigned int outCount, i;
            objc_property_t *properties = class_copyPropertyList(modelClass, &outCount);
            
            for (i = 0; i < outCount; i++) {
                objc_property_t property = properties[i];
                
                NSString *name = [NSString stringWithCString: property_getName(property)
                                                    encoding: NSASCIIStringEncoding];
                NSString *attr = [NSString stringWithCString: property_getAttributes(property)
                                                    encoding: NSASCIIStringEncoding];

                NSArray *chunks = [attr componentsSeparatedByString: @","];
                //NSLog(@"%@", chunks);
                NSString *type = [chunks objectAtIndex: 0];
                if ([[type substringWithRange: NSMakeRange(1, 1)] isEqualToString: @"@"]) {
                    type = [type substringWithRange: NSMakeRange(3, [type length] - 4)];
                } else {
                    // Primitive type
                    type = [type substringFromIndex: 1];
                }
                
                // Figure out if we need uniqueness
                BOOL unique = [class shouldColumnBeUnique: name];
                
                if (![name isEqualToString: id_column_name]) {
                    NSLog(@"%@ %@ %@", name, type, unique ? @"Unique" : @"");
                    
                    NSDictionary *typeMap = [NSDictionary dictionaryWithObjectsAndKeys: 
                                             @"INTEGER", @"i",
                                             @"INTEGER", @"I",
                                             @"FLOAT", @"f",
                                             @"INTEGER", @"l",
                                             @"INTEGER", @"s",
                                             @"INTEGER", @"c",
                                             @"INTEGER", @"NSNumber",
                                             @"TEXT", @"NSString",
                                             @"BLOB", @"NSData",
                                             @"INTEGER", @"NSDate",
                                             nil];
                    
                    NSString *column;
                    if ((column = [typeMap objectForKey: type])) {
                        if (unique) {
                            column = [column stringByAppendingString: @" UNIQUE"];
                        }
                        
                        [columns setObject: column forKey: name];
                        
                    } else {
                        // Ignore unknown
                        NSLog(@"Ignoring column %@ of type %@", name, type);
                    }
                    
                }
            }
            
            NSLog(@"%@", columns);
            
            NSString *query = [NSString stringWithFormat: @"CREATE TABLE %@ (", table_name];
            NSEnumerator *enumerator = [columns keyEnumerator];
            NSString *columnName;
            int j = 0, m = [columns count];
            while ((columnName = [enumerator nextObject])) {
                query = [query stringByAppendingFormat: @"%@ %@", columnName, [columns objectForKey: columnName]];
                if (j < m - 1) {
                    query = [query stringByAppendingString: @", "];
                }
                j++;
            }
            [columns release];
            query = [query stringByAppendingString: @")"];
            
            NSLog(@"%@", query);
            [db query: query withError: &error];
            if (error) {
                NSLog(@"Failed to create table %@: %@", table_name, error);
            } else {
                
                // Retrieve indexes
                NSArray *indexesTuples = [class indexes];
                m = [indexesTuples count];
                for (j = 0; j < m; j++) {
                    if ([[indexesTuples objectAtIndex: j] isKindOfClass: [NSString class]]) {
                        NSString *name = [indexesTuples objectAtIndex: j];
                        NSString *indexName = [name stringByAppendingString: @"Index"];
                        NSString *indexQuery = [NSString stringWithFormat: @"CREATE INDEX IF NOT EXISTS %@ ON %@ (%@)", indexName, table_name, name];
                        NSLog(@"%@", indexQuery);
                        
                        [db query: indexQuery withError: &error];
                        if (error) {
                            NSLog(@"Failed to create index %@: %@", indexName, error);
                        }
                        
                    } else if ([[indexesTuples objectAtIndex: j] isKindOfClass: [NSArray class]]) {
                        // Indexing multiple columns
                        NSArray *tuples = [indexesTuples objectAtIndex: j];
                        NSString *indexName = [[tuples componentsJoinedByString: @""] stringByAppendingString: @"Index"];
                        NSString *name = [tuples componentsJoinedByString: @","];
                        
                        NSString *indexQuery = [NSString stringWithFormat: @"CREATE INDEX IF NOT EXISTS %@ ON %@ (%@)", indexName, table_name, name];
                        NSLog(@"%@", indexQuery);
                        
                        [db query: indexQuery withError: &error];
                        if (error) {
                            NSLog(@"Failed to create index %@: %@", indexName, error);
                        }
                        
                    }
                }
                
            }
            
        }
    }
    
    [tables release];

    return db;
}

@end

