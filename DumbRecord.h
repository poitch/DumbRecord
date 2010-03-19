/*
 *  DRecord.h
 *  DRecord
 *
 *  Created by Jerome Poichet on 3/12/10.
 *  Copyright 2010 Jerome Poichet. All rights reserved.
 *
 */
#if TARGET_OS_IPHONE
#import <Foundation/Foundation.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#import "JPLite.h"
#import "JPModel.h"

@interface DRecord : NSObject {
    
}

+ (void) setup: (NSString *) database;
+ (void) setup: (NSString *) database withModels: (NSArray *)models;

@end