# DRecord.framework

Dumb Record (DRecord) is a very simplistic ORM for Objective-C and Cocoa project. It is built on top of sqlite.

## Installation

* Build the framework
* Copy the framework to your project
* Add a copy build phase, edit the type from Resource to Framework
* Drag and drop the framework to that new copy phase

## Utilisation

Models must inherit the JPModel class, the attributes must correspond to the columns of the table.

The name of the class will be pluralized (it's adding an `s` to the lower cased class name).

For the following SQL

    CREATE TABLE tracks (track_id INTEGER PRIMARY KEY, name VARCHAR(255), duration INTEGER);

You should use the following class declaration

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

To update the value of that object

    track.duration = [NSNumber numberWithInt: 136];
    [track update];

To remove that object from the database

    [track delete];

After that you can find objects in a sqlite database as follows:

    JPLite *db = [JPLite liteWithDatabase: @"tracks.sql"];

    NSArray *tracks = [Track findWhere: [NSDictionary dictionaryWithObjectsAndKeys: @"Song title", @"name", nil] inDB: db];

The where dictionary is column name for the key and the value to match the search for. It does `AND` on all entries.

## Notes:

The primary key has to be the name of the class (lower case) followed by _id.

For now you would need to create code to create the tables and maintain the schema up-to-date.


## TODO

Add more options to search for objects (bringing support for `OR` and `LIMIT`)


