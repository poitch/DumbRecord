//
//  JPModel.h
//  DumbRecord
//
//  Created by Jerome Poichet on 3/12/10.
//  Copyright 2010 Jerome Poichet. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <Foundation/Foundation.h>
#else
#import <Cocoa/Cocoa.h>
#endif

@class DRLite;

@interface DRModel : NSObject {

}

- (void) insert: (DRLite *) db;
- (void) update: (DRLite *) db;
- (void) delete: (DRLite *) db;

+ (NSArray *) findWhere: (NSDictionary *) clauses inDB: (DRLite *)db;

@end
