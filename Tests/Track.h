//
//  Track.h
//  DumbRecord
//
//  Created by Jerome Poichet on 3/16/10.
//  Copyright 2010 Jerome Poichet. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DumbRecord.h"

@interface Track : DRModel {
    NSNumber *track_id;
    NSString *name;
    NSNumber *duration;
    
    float someFloat;
}

@property (nonatomic, retain) NSNumber *track_id;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSNumber *duration;
@property (nonatomic) float someFloat;

@end
