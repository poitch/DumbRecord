# DRecord

Dumb Record (DRecord) is a very simplistic ORM for Objective-C and Cocoa project. It is built on top of sqlite.

## Installation

* Build the framework
* Copy the framework to your project
* Add a copy build phase, edit the type from Resource to Framework
* Drag and drop the framework to that new copy phase

## Utilisation

Models must inherit the JPModel class, the attributes must correspond to the columns of the table.

The name of the class will be pluralize (as of this writting, it's adding an `s` to the lower cased class name.

You should also use Objective-C 2.0 period notation for those attributes.

    #import <Cocoa/Cocoa.h>
    #import "DRecord/DRecord.h"

    @interface Track : JPModel {
        NSNumber *track_id;
        NSString *name;
        NSNumber *duration;
        NSNumber *created_at;
    }

    @property (nonatomic, retain) NSNumber *track_id;
    @property (nonatomic, retain) NSString *name;
    @property (nonatomic, retain) NSNumber *duration;

    @end

To insert a new object in the database

    JPLite *db = [JPLite liteWithDatabase: @"tracks.sql"];

    Track *track = [[Track alloc] init];
    track.name = @"Song title";
    track.duration = [NSNumber numberWithInt: 156];
    [track insert];

    // To update the value of that object
    track.duration = [NSNumber numberWithInt: 136];
    [track update];

    // To remove that object from the database
    [track delete];

After that you can find objects in a sqlite database as follows:

    JPLite *db = [JPLite liteWithDatabase: @"tracks.sql"];

    NSArray *tracks = [Track findWhere: [NSDictionary dictionaryWithObjectsAndKeys: @"Song title", @"name", nil] inDB: db];

    #import "DRecord

A the primary key has to be the name of the class (lower case) followed by _id.


