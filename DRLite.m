//
//  DRLite.m
//  DumbRecord
//
//  Created by Jerome Poichet on 5/13/09.
//  Copyright 2009 Jerome Poichet. All rights reserved.
//

#import "DRLite.h"

static NSError *generate_error(int code, NSString *str)
{       
    NSDictionary *dict = [NSDictionary dictionaryWithObject:str forKey:NSLocalizedDescriptionKey]; 
    return [NSError errorWithDomain:@"com.frencaze.DumbRecord.ErrorDomain" code:code userInfo:dict]; 
}

static BOOL __drlite_verbose = false;

@implementation DRLite

@synthesize databasePath = _databasePath;
@synthesize created = _created;

+ (DRLite *) liteWithDatabase: (NSString *) database
{
    return [[[DRLite alloc] initWithDatabase: database] autorelease];
}

- (id) initWithDatabase: (NSString *) database
{
    if (self = [super init]) {
        _databasePath = [database retain];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath: _databasePath] == YES) {
            _created = NO;
        } else {
            _created = YES;
        }
        
        if(sqlite3_open([_databasePath UTF8String], &_database) != SQLITE_OK) {
        }
    }
    return self;
}

- (void) dealloc
{
    if (_database) {
        sqlite3_close(_database);
    }
    [_databasePath release];
    [super dealloc];
}

- (BOOL) insert: (NSString *) query withArguments: (NSArray *) args andError: (NSError **) error
{
    sqlite3_stmt *stmt;

    if (__drlite_verbose) NSLog(@"%@", query);
    
    if (!_database) {
        if (error) {
            *error = generate_error(100, @"Could not open database");            
        }
        return NO;
    }
    
    @synchronized(self) {
        if(sqlite3_prepare_v2(_database, [query UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
            if (error) {
                *error = generate_error(sqlite3_errcode(_database), [NSString stringWithCString: sqlite3_errmsg(_database) encoding: NSUTF8StringEncoding]);            
            }
            return NO;
        }

        if (args) {
            int i = 1;
            for(id arg in args) {
                if ([[arg className] isEqualToString: @"NSCFNumber"]) {
                    NSNumber *aNumber = arg;
                    if((strcmp([aNumber objCType], @encode(int))) == 0) {
                        if (SQLITE_OK != sqlite3_bind_int(stmt, i, [arg intValue])) {
                            if (error) {
                                *error = generate_error(201, [NSString stringWithFormat: @"Could not bind NSNumber argument %d", i]);
                            }
                            return NO;
                        }                        
                    } else if((strcmp([aNumber objCType], @encode(double))) == 0) {
                        if (SQLITE_OK != sqlite3_bind_double(stmt, i, [arg doubleValue])) {
                            if (error) {
                                *error = generate_error(202, [NSString stringWithFormat: @"Could not bind NSNumber argument %d", i]);
                            }
                            return NO;
                        }                        
                        
                    } else if((strcmp([aNumber objCType], @encode(long))) == 0) {
                        if (SQLITE_OK != sqlite3_bind_double(stmt, i, [arg longValue])) {
                            if (error) {
                                *error = generate_error(203, [NSString stringWithFormat: @"Could not bind NSNumber argument %d", i]);
                            }
                            return NO;
                        }                        
                    } else if((strcmp([aNumber objCType], @encode(float))) == 0) {
                        if (SQLITE_OK != sqlite3_bind_double(stmt, i, [arg floatValue])) {
                            if (error) {
                                *error = generate_error(204, [NSString stringWithFormat: @"Could not bind NSNumber argument %d", i]);
                            }
                            return NO;
                        }                        
                    } else {
                        if (error) {
                            *error = generate_error(205, [NSString stringWithFormat: @"Could not bind NSNumber argument %d", i]);
                        }
                        return NO;
                    }
                } else if ([[arg className] isEqualToString: @"NSCFString"]) {
                    if (SQLITE_OK != sqlite3_bind_text(stmt, i, [arg UTF8String], strlen([arg UTF8String]), NULL)) {
                        if (error) {
                            *error = generate_error(206, [NSString stringWithFormat: @"Could not bind NSString argument %d", i]);
                        }
                        return NO;
                    }                        
                } else if ([[arg className] isEqualToString: @"__NSCFDate"]) {
                    if (SQLITE_OK != sqlite3_bind_double(stmt, i, (long)[arg timeIntervalSince1970])) {
                        if (error) {
                            *error = generate_error(207, [NSString stringWithFormat: @"Could not bind NSDate argument %d", i]);
                        }
                        return NO;
                    }                        
                } else if ([[arg className] isEqualToString: @"NSCFData"]) {
                    if (SQLITE_OK != sqlite3_bind_blob(stmt, i, [arg bytes], [arg length], NULL)) {
                        if (error) {
                            *error = generate_error(208, [NSString stringWithFormat: @"Could not bind NSData argument %d", i]);
                        }
                        return NO;
                    }                        
                } else {
                    if (error) {
                        *error = generate_error(209, [NSString stringWithFormat: @"Could not bind %@ argument %d", [arg className], i]);
                    }
                    return NO;
                }
                i++;
            }
        }
                    
        if (SQLITE_DONE != sqlite3_step(stmt)) {
            if (error) {
                *error = generate_error(301, @"Could not execute query");
            }
            return NO;
        }
        
        if (SQLITE_OK != sqlite3_finalize(stmt)) {
            if (error) {
                *error = generate_error(302, @"Could not execute query");
            }
            return NO;
        }
            

    }
    
    return YES;
}

- (NSArray *)query: (NSString *)query withError: (NSError **)error
{
    NSMutableArray *results = nil;
    sqlite3_stmt *stmt;

    if (__drlite_verbose) NSLog(@"%@", query);
    
    if (!_database) {
        if (error) {
            *error = generate_error(100, @"Could not open database");            
        }
        return nil;
    }
    
    @synchronized(self) {
        if(sqlite3_prepare_v2(_database, [query UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
            if (error) {
                *error = generate_error(sqlite3_errcode(_database), [NSString stringWithCString: sqlite3_errmsg(_database) encoding: NSUTF8StringEncoding]);            
            }
            return nil;
        }

        while (sqlite3_step(stmt) == SQLITE_ROW) {
            if (!results) {
                results = [[NSMutableArray alloc] init];
            }

            int i, n = sqlite3_column_count(stmt);
            NSMutableDictionary *row = [NSMutableDictionary dictionaryWithCapacity: n];
        
            for (i = 0; i < n; i++) {
                const char *name = sqlite3_column_name(stmt, i);
                int type = sqlite3_column_type(stmt, i);
                switch (type) {
                    case SQLITE_INTEGER:
                    {
                        int v = sqlite3_column_int(stmt, i);
                        [row setObject: [NSNumber numberWithInt: v] 
                                forKey: [NSString stringWithCString: name encoding: NSUTF8StringEncoding]];
                        break;
                    }
                    case SQLITE_FLOAT:
                    {
                        double v = sqlite3_column_double(stmt, i);
                        [row setObject: [NSNumber numberWithFloat: v] 
                                forKey: [NSString stringWithCString: name encoding: NSUTF8StringEncoding]];
                        break;
                    }
                    default:
                    case SQLITE_TEXT:
                    {
                        const char *v = (const char *)sqlite3_column_text(stmt, i);
                        [row setObject: [NSString stringWithCString:v encoding: NSUTF8StringEncoding] 
                                forKey: [NSString stringWithCString: name encoding: NSUTF8StringEncoding]];
                        break;
                    }
                    case SQLITE_BLOB:
                    {
                        const void *v = sqlite3_column_blob(stmt, i);
                        int len = sqlite3_column_bytes(stmt, i);
                        [row setObject: [NSData dataWithBytes: v length:len] 
                                forKey: [NSString stringWithCString: name encoding: NSUTF8StringEncoding]];
                        break;
                    }
                    case SQLITE_NULL:
                    {
                        [row setObject: [NSNull null] 
                                forKey: [NSString stringWithCString: name encoding: NSUTF8StringEncoding]];
                        break; 
                    }
                }
            }
            
            [results addObject: row];
        }

        sqlite3_finalize(stmt);
    }
    return [results autorelease];
}

- (NSNumber *)lastId
{
    return [NSNumber numberWithLongLong: sqlite3_last_insert_rowid(_database)];
}

+ (void) setVerbose: (BOOL) verbose
{
    __drlite_verbose = verbose;
}

@end
