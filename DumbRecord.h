//
//  DRecord.h
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

#import "DRLite.h"
#import "DRModel.h"

@interface DumbRecord : NSObject {
    
}

+ (DRLite *) setup: (NSString *) database;
+ (DRLite *) setup: (NSString *) database withModels: (NSArray *)models;

@end