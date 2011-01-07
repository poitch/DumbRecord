//
//  LiteTest.m
//  DumbRecord
//
//  Created by Jerome Poichet on 1/7/11.
//  Copyright 2011 Jerome Poichet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DRLite.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath: @"TestLite.sql"]) {
        NSLog(@"Removing previous file");
        [fm removeItemAtPath: @"TestLite.sql" error: nil];
    }
    
    [DRLite setVerbose: YES];
    
    DRLite *db = [[DRLite alloc] initWithDatabase: @"TestLite.sql"];
    
    NSString *query;
    NSError *error = nil;
    
    query = @"CREATE TABLE person (id INTEGER PRIMARY KEY, name VARCHAR(255), created_at INTEGER)";
    [db query: query withError: &error];
    
    if (error) {
        NSLog(@"%@", error);
        goto cleanup;
    }
    
    NSLog(@"Table created");
    
    query = @"INSERT INTO person (name, created_at) VALUES (?,?)";
    if (![db insert: query withArguments: [NSArray arrayWithObjects: @"Jerome", NSNOW(), nil] andError: &error]) {
        NSLog(@"Failed to insert %@", error);
        goto cleanup;
    }

    query = @"INSERT INTO person (name, created_at) VALUES (?,?)";
    if (![db insert: query withArguments: [NSArray arrayWithObjects: @"Jerome", [NSDate date], nil] andError: &error]) {
        NSLog(@"Failed to insert %@", error);
        goto cleanup;
    }
    
    
    query = @"SELECT * FROM person";
    NSLog(@"%@", [db query: query withError: &error]);
    
    
    
cleanup:    
    [pool drain];
    return 0;
}
