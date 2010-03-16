//
//  Track.h
//  DRecord
//
//  Created by Jerome Poichet on 3/16/10.
//  Copyright 2010 OnLive, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DRecord.h"

@interface Track : JPModel {
    NSNumber *track_id;
    NSString *name;
    NSNumber *duration;
}

@property (nonatomic, retain) NSNumber *track_id;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSNumber *duration;

@end
