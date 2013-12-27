//
//  SWMainWindowController.m
//  WWDC Video Search
//
//  Created by Simon Whitaker on 26/12/2013.
//  Copyright (c) 2013 Simon Whitaker. All rights reserved.
//

#import "SWMainWindowController.h"
#import <sqlite3.h>

static NSString const *kResultsSessionIdKey = @"sessionId";
static NSString const *kResultsTitleKey = @"title";
static NSString const *kResultsDescriptionKey = @"description";

@interface SWMainWindowController()
@property (nonatomic) IBOutlet NSTableView *tableView;
@property (nonatomic) NSString *databaseFilePath;
@property (nonatomic) NSArray *results;
@property (nonatomic) sqlite3 *db;
@property (nonatomic) sqlite3_stmt *query;
@end

@implementation SWMainWindowController

- (void)SW_commonInit {
    self.databaseFilePath = [[NSBundle mainBundle] pathForResource:@"sessions.sqlite3" ofType:nil];
}

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        [self SW_commonInit];
    }
    return self;
}

- (void)dealloc {
    if (self.db) {
        sqlite3_close(self.db);
    }
}

#pragma mark - Event handlers

- (void)keyDown:(NSEvent *)theEvent {
    NSLog(@"Got keyDown event: %@", theEvent);
    
    unichar keyCharacter = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    if (self.tableView.selectedRow >= 0 && (keyCharacter == NSEnterCharacter || keyCharacter == NSCarriageReturnCharacter)) {
        
        NSDictionary *data = self.results[self.tableView.selectedRow];
        NSNumber *sessionId = data[kResultsSessionIdKey];
        
        NSString *urlString = [NSString stringWithFormat:@"https://developer.apple.com/wwdc/videos/index.php?id=%@", sessionId];
        NSURL *url = [NSURL URLWithString:urlString];
        [[NSWorkspace sharedWorkspace] openURL:url];
    } else {
        // Pass on the key event
        [self interpretKeyEvents:@[theEvent]];
    }
}

#pragma mark - Accessors

- (sqlite3 *)db {
    if (!_db) {
        sqlite3 *db;
        int result = sqlite3_open([self.databaseFilePath UTF8String], &db);
        if (result == SQLITE_OK) {
            _db = db;
        }
    }
    return _db;
}

- (sqlite3_stmt *)query {
    if (!_query) {
        NSString *queryString = @"SELECT docid, title, description FROM session WHERE session MATCH ?";
        sqlite3_stmt *stmt;
        int result = sqlite3_prepare_v2(self.db, [queryString UTF8String], -1, &stmt, NULL);
        if (result == SQLITE_OK) {
            _query = stmt;
        }
        
    }
    return _query;
}

- (void)setSearchTerm:(NSString *)searchTerm {
    _searchTerm = searchTerm;
    [self SW_fetchResults];
    [self.tableView reloadData];
}

#pragma mark - NSTableViewDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.results count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSDictionary *cellData = self.results[row];
    
    NSString *identifier = tableColumn.identifier;
    if ([identifier isEqualToString:@"MainCell"]) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:identifier owner:self];
        cellView.textField.stringValue = cellData[kResultsTitleKey];
        return cellView;
    }
    return nil;
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
                                            kResultsSessionIdKey: @(docid),
                                            kResultsTitleKey: [NSString stringWithCString:title encoding:NSUTF8StringEncoding],
                                            kResultsDescriptionKey: [NSString stringWithCString:description encoding:NSUTF8StringEncoding],
                                            }];
            }
        }
    }
    
    self.results = [NSArray arrayWithArray:mutableResults];
}


@end
