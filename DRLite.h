//
//  DRLite.h
//  DumbRecord
//
//  Created by Jerome Poichet on 5/13/09.
//  Copyright 2009 Jerome Poichet. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <Foundation/Foundation.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#import <sqlite3.h>


@interface DRLite : NSObject {
@private
    NSString *_databasePath;
    sqlite3 *_database;
    BOOL _created;
}

@property (nonatomic, retain) NSString *databasePath;
@property BOOL created;

+ (DRLite *) liteWithDatabase: (NSString *) database;
- (id) initWithDatabase: (NSString *) database;

- (NSArray *)query: (NSString *)query withError: (NSError **)error;
- (NSNumber *)lastId; 

@end
