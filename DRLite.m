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
                    [row setObject: [NSNumber numberWithInt: v] forKey: [NSString stringWithCString: name encoding: NSUTF8StringEncoding]];
                    break;
                }
                case SQLITE_FLOAT:
                {
                    double v = sqlite3_column_double(stmt, i);
                    [row setObject: [NSNumber numberWithFloat: v] forKey: [NSString stringWithCString: name encoding: NSUTF8StringEncoding]];
                    break;
                }
                default:
                case SQLITE_TEXT:
                {
                    const char *v = (const char *)sqlite3_column_text(stmt, i);
                    [row setObject: [NSString stringWithCString:v encoding: NSUTF8StringEncoding] forKey: [NSString stringWithCString: name encoding: NSUTF8StringEncoding]];
                    break;
                }
                case SQLITE_BLOB:
                {
                    const void *v = sqlite3_column_blob(stmt, i);
                    int len = sqlite3_column_bytes(stmt, i);
                    [row setObject: [NSData dataWithBytes: v length:len] forKey: [NSString stringWithCString: name encoding: NSUTF8StringEncoding]];
                    break;
                }
                case SQLITE_NULL:
                {
                    [row setObject: [NSNull null] forKey: [NSString stringWithCString: name encoding: NSUTF8StringEncoding]];
                    break; 
                }
            }
        }
        
        [results addObject: row];
    }

    sqlite3_finalize(stmt);
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
