//
//  JPModel.h
//  JPData
//
//  Created by Jerome Poichet on 3/12/10.
//  Copyright 2010 Jerome Poichet. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <Foundation/Foundation.h>
#else
#import <Cocoa/Cocoa.h>
#endif

@class JPLite;

@interface JPModel : NSObject {

}

- (void) insert: (JPLite *) db;
- (void) update: (JPLite *) db;
- (void) delete: (JPLite *) db;

+ (NSArray *) findWhere: (NSDictionary *) clauses inDB: (JPLite *)db;

@end
