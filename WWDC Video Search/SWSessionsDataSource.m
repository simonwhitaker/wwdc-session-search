//
//  SWSessionsDataSource.m
//  WWDC Video Search
//
//  Created by Simon Whitaker on 26/12/2013.
//  Copyright (c) 2013 Simon Whitaker. All rights reserved.
//

#import "SWSessionsDataSource.h"
#import <sqlite3.h>

@interface SWSessionsDataSource()
@property (nonatomic) NSArray *results;
@property (nonatomic) sqlite3 *db;
@property (nonatomic) sqlite3_stmt *query;
@end

@implementation SWSessionsDataSource

- (id)initWithSQLiteFilePath:(NSString *)dbFilePath {
    self = [super init];
    if (self) {
        int result = sqlite3_open([dbFilePath UTF8String], &_db);
        if (result == SQLITE_OK) {
            NSString *query = @"SELECT docid, title, description FROM session WHERE session MATCH ?";
            sqlite3_stmt *stmt;
            int result = sqlite3_prepare_v2(self.db, [query UTF8String], -1, &stmt, NULL);
            if (result == SQLITE_OK) {
                self.query = stmt;
            }
        }
    }
    return self;
}

- (void)dealloc {
    if (self.db) {
        sqlite3_close(self.db);
    }
}

#pragma mark - Accessors

- (void)setSearchTerm:(NSString *)searchTerm {
    _searchTerm = searchTerm;
    [self SW_fetchResults];
}

#pragma mark - NSTableViewDataSource methods

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

#pragma mark - Private methods

- (void)SW_fetchResults {
    NSMutableArray *mutableResults = [NSMutableArray array];
    
    if (self.query && sqlite3_reset(self.query) == SQLITE_OK) {
        const char *searchTermUTF8String = [[self.searchTerm stringByAppendingString:@"*"] UTF8String];
        int result = sqlite3_bind_text(self.query, 1, searchTermUTF8String, -1, SQLITE_TRANSIENT);
        if (result == SQLITE_OK) {
            while (sqlite3_step(self.query) == SQLITE_ROW) {
                int docid = sqlite3_column_int(self.query, 0);
                const char *title = (const char*)sqlite3_column_text(self.query, 1);
                const char *description = (const char*)sqlite3_column_text(self.query, 2);
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
