//
//  setup.m
//  DumbRecord
//
//  Created by Jerome Poichet on 3/16/10.
//  Copyright 2010 Jerome Poichet. All rights reserved.
//

#import "SetupTests.h"
#import "Track.h"

@implementation SetupTests

- (void) testCreate
{
    NSArray *rows = nil;
    NSError *error = nil;
    int i, n;    
    NSString *database = @"testCreate.sql";

    [[NSFileManager defaultManager] removeItemAtPath: database error: &error];
    
    
    
    
    DRLite *db = [DumbRecord setup: database withModels: [NSArray arrayWithObjects: @"Track", nil]];
    
    rows = [db query: @"SELECT name FROM sqlite_master WHERE type='table' ORDER BY name" withError: &error];
    n = [rows count];
    BOOL found = NO;
    for (i = 0; i < n; i++) {
        if ([[[rows objectAtIndex: i] objectForKey: @"name"] isEqualToString: @"tracks"]) {
            found = YES;
            break;
        }
    }
    
    STAssertTrue(found, @"Could not find tracks table in database");
}

- (void) testInsert
{
    NSString *database = @"testCreate.sql";

    DRLite *db = [[DRLite alloc] initWithDatabase: database];
    Track *t1 = [[Track alloc] init];
    t1.name = @"Track1";
    t1.duration = [NSNumber numberWithInt: 350];
    t1.someFloat = 3.14;
    [t1 insert: db];
    STAssertEquals(1, t1.track_id, @"track_id was not updated");
    
    NSArray *tracks = [Track findWhere: [NSDictionary dictionaryWithObjectsAndKeys: @"Track1", @"name", nil] inDB: db];
    STAssertNotNil(tracks, @"find should have returned an array");
    NSLog(@"%@", tracks);
    STAssertTrue([tracks count] == 1, @"Number of items returned should be 1 but was %d", [tracks count]);
    STAssertTrue([[[tracks objectAtIndex: 0] name] isEqualToString: @"Track1"], @"item found should have name Track1 but has %@", [[tracks objectAtIndex: 0] name]);
    
}

@end