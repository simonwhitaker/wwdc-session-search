//
//  SWSessionsDataSource.m
//  WWDC Video Search
//
//  Created by Simon Whitaker on 26/12/2013.
//  Copyright (c) 2013 Netcetera. All rights reserved.
//

#import "SWSessionsDataSource.h"
#import <sqlite3.h>

@interface SWSessionsDataSource()
@property (nonatomic) NSArray *results;
@property (nonatomic) sqlite3 *db;
@end

@implementation SWSessionsDataSource

- (void)dealloc {
    if (self.db) {
        sqlite3_close(self.db);
    }
}

- (void)setSearchTerm:(NSString *)searchTerm {
    _searchTerm = searchTerm;
    [self SW_fetchResults];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.results count];
}

/* This method is required for the "Cell Based" TableView, and is optional for the "View Based" TableView. If implemented in the latter case, the value will be set to the view at a given row/column if the view responds to -setObjectValue: (such as NSControl and NSTableCellView).
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSDictionary *dictionary = self.results[row];
    if ([tableColumn.identifier isEqualToString:@"session"]) {
        return dictionary[@"docid"];
    } else {
        return dictionary[@"title"];
    }
}

#pragma mark - Accessors

- (sqlite3 *)db {
    if (!_db) {
        NSString *filename = [[NSBundle mainBundle] pathForResource:@"sessions.sqlite3" ofType:nil];
        int result = sqlite3_open([filename UTF8String], &_db);
        if (result != SQLITE_OK) {
            NSLog(@"Error on opening database: %s", sqlite3_errmsg(_db));
        }
    }
    return _db;
}

- (void)SW_fetchResults {
    NSMutableArray *mutableResults = [NSMutableArray array];
    
    NSString *query = @"SELECT docid, title, description FROM session WHERE session MATCH ?";
    sqlite3_stmt *stmt;
    int result = sqlite3_prepare_v2(self.db, [query UTF8String], -1, &stmt, NULL);
    if (result == SQLITE_OK) {
        const char *searchTermUTF8String = [[self.searchTerm stringByAppendingString:@"*"] UTF8String];
        result = sqlite3_bind_text(stmt, 1, searchTermUTF8String, -1, SQLITE_TRANSIENT);
        if (result == SQLITE_OK) {
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                int docid = sqlite3_column_int(stmt, 0);
                const char *title = (const char*)sqlite3_column_text(stmt, 1);
                const char *description = (const char*)sqlite3_column_text(stmt, 2);
                [mutableResults addObject:@{
                                            @"docid": @(docid),
                                            @"title": [NSString stringWithCString:title encoding:NSUTF8StringEncoding],
                                            @"description": [NSString stringWithCString:description encoding:NSUTF8StringEncoding],
                                            }];
            }
        }
    }
    self.results = [NSArray arrayWithArray:mutableResults];
}

@end
