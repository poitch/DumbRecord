# DumbRecord.framework

Dumb Record is a very simplistic ORM for Objective-C and Cocoa project. It is built on top of sqlite.

## Installation

* Build the framework
* Copy the framework to your project
* Add a copy build phase, edit the type from Resource to Framework
* Drag and drop the framework to that new copy phase

## Utilisation

Models must inherit the DRModel class, the attributes must correspond to the columns of the table.

All properties must be declared using Objective-C 2.0 dot notation (@property ...)

There should be one column name <table_name>_id and it has to be of type int.

The name of the class will be pluralized (it's adding an `s` to the lower cased class name).

You should use the following class declaration

    #import <Cocoa/Cocoa.h>
    #import "DumbRecord/DumbRecord.h"

    @interface Track : DRModel {
        int track_id;
        NSString *name;
        NSNumber *duration;
        NSNumber *created_at;
    }

    @property (nonatomic) int track_id;
    @property (nonatomic, retain) NSString *name;
    @property (nonatomic, retain) NSNumber *duration;

    @end

### Using the schema-maintaining technique

    NSString *database = @"tracks.sql";
    [DumbRecord setup: database withModels: [NSArray arrayWithObjects: @"Track", nil]];

This will auto-inspect the classes passed in the array and automatically create the tables (it won't update exisiting table - see TODO list)

### Creating the database yourself

For the following SQL

    CREATE TABLE tracks (track_id INTEGER PRIMARY KEY, name VARCHAR(255), duration INTEGER);

### Inserting an object

To insert a new object in the database

    DRLite *db = [DRLite liteWithDatabase: @"tracks.sql"];

    Track *track = [[Track alloc] init];
    track.name = @"Song title";
    track.duration = [NSNumber numberWithInt: 156];
    [track insert: db];

### Updating an object

To update the value of that object

    track.duration = [NSNumber numberWithInt: 136];
    [track update: db];

### Removing an object

To remove that object from the database

    [track delete: db];

### Searching for object

After that you can find objects in a sqlite database as follows:

    DRLite *db = [DRLite liteWithDatabase: @"tracks.sql"];

    NSArray *tracks = [Track findWhere: [NSDictionary dictionaryWithObjectsAndKeys: @"Song title", @"name", nil] inDB: db];

The where dictionary is column name for the key and the value to match the search for. It does `AND` on all entries.

## Notes:

The primary key has to be the name of the class (lower case) followed by _id.

For now you would need to create code to create the tables and maintain the schema up-to-date.


## TODO

* Add more options to search for objects (bringing support for `OR` and `LIMIT`)
* Automagically update the underlying schema
* Use bindings for the queries to prevent SQL Injections
* Improve pluralization method
* Add support for NSDate


