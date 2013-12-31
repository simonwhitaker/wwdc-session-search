//
//  SWMainWindowController.m
//  WWDC Video Search
//
//  Created by Simon Whitaker on 26/12/2013.
//  Copyright (c) 2013 Simon Whitaker. All rights reserved.
//

#import "SWMainWindowController.h"
#import "SWSessionsTableCellView.h"

#import <sqlite3.h>

static NSString const *kResultsYearKey = @"year";
static NSString const *kResultsSessionNumberKey = @"session_number";
static NSString const *kResultsTitleKey = @"title";
static NSString const *kResultsDescriptionKey = @"description";
static NSString const *kResultsTrackKey = @"track";
static NSString const *kResultsOffsetsKey = @"offsets";

NSUInteger characterOffsetForByteOffsetInUTF8String(NSUInteger byteOffset, const char *string) {
    NSUInteger result = 0;
    for (NSUInteger i = 0; i < byteOffset; i++) {
        char c = string[i];
        if (c & 0x80) {
            // We're at the first byte of a UTF-8 character. Move to the last byte.
            while ((string[i+1] & 0x80) && i < byteOffset) {
                i++;
            }
        }
        result++;
    }
    return result;
}


@interface SWMainWindowController()
@property (nonatomic) NSString *databaseFilePath;
@property (nonatomic) NSArray *results;
@property (nonatomic) sqlite3 *db;
@property (nonatomic) sqlite3_stmt *searchResultsQuery;
@property (nonatomic) sqlite3_stmt *allSessionsQuery;
@end

@implementation SWMainWindowController

- (void)SW_commonInit {
    self.databaseFilePath = [[NSBundle mainBundle] pathForResource:@"sessions.sqlite3" ofType:nil];
    [self SW_fetchResults];
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

- (void)setTableView:(NSTableView *)tableView {
    if (tableView != _tableView) {
        _tableView = tableView;
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.doubleAction = @selector(SW_handleDoubleClick:);
    }
}

#pragma mark - Event handlers

- (void)keyDown:(NSEvent *)theEvent {
    unichar keyCharacter = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    if (self.tableView.selectedRow >= 0 && (keyCharacter == NSEnterCharacter || keyCharacter == NSCarriageReturnCharacter)) {
        [self SW_launchWebsiteForRow:self.tableView.selectedRow];
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

- (sqlite3_stmt *)searchResultsQuery {
    if (!_searchResultsQuery) {
        // session is a plain old table, session_fts is a virtual full text search table. See http://www.sqlite.org/fts3.html
        NSString *queryString = @"SELECT s.year, s.session_number, s.title, s.description, s.track, offsets(session_fts) FROM session s, session_fts WHERE s.rowid = session_fts.docid AND session_fts MATCH ?";
        sqlite3_stmt *stmt;
        int result = sqlite3_prepare_v2(self.db, [queryString UTF8String], -1, &stmt, NULL);
        if (result == SQLITE_OK) {
            _searchResultsQuery = stmt;
        }
        
    }
    return _searchResultsQuery;
}

- (sqlite3_stmt *)allSessionsQuery {
    if (!_allSessionsQuery) {
        NSString *queryString = @"SELECT year, session_number, title, description, track FROM session ORDER BY year DESC, session_number";
        sqlite3_stmt *stmt;
        int result = sqlite3_prepare_v2(self.db, [queryString UTF8String], -1, &stmt, NULL);
        if (result == SQLITE_OK) {
            _allSessionsQuery = stmt;
        }
    }
    return _allSessionsQuery;
}

- (void)setSearchTerm:(NSString *)searchTerm {
    _searchTerm = searchTerm;
    [self SW_fetchResults];
    [self.tableView reloadData];
    if ([self.results count] > 0) {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
        [self.tableView selectRowIndexes:indexSet byExtendingSelection:NO];
    }
}

#pragma mark - NSTableViewDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.results count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    static NSDictionary *standardColors = nil;
    if (standardColors == nil) {
        /* Map session numbers to colors. 
         *
         *   1xx = General / Special Events
         *   2xx = Frameworks / Essentials
         *   3xx = Services
         *   4xx = Tools
         *   5xx = Graphics and Games
         *   6xx = Media / Web
         *   7xx = Core OS
         */
        standardColors = @{
            @1: [NSColor colorWithDeviceRed:0.61 green:0.61 blue:0.61 alpha:1.0],
            @2: [NSColor colorWithDeviceRed:0.49 green:0.66 blue:0.99 alpha:1.0],
            @3: [NSColor colorWithDeviceRed:0.61 green:0.81 blue:0.18 alpha:1.0],
            @4: [NSColor colorWithDeviceRed:0.99 green:0.45 blue:0.26 alpha:1.0],
            @5: [NSColor colorWithDeviceRed:1.00 green:0.84 blue:0.24 alpha:1.0],
            @6: [NSColor colorWithDeviceRed:0.79 green:0.34 blue:0.89 alpha:1.0],
            @7: [NSColor colorWithDeviceRed:0.36 green:0.80 blue:0.75 alpha:1.0],
        };
    }

    NSDictionary *cellData = self.results[row];
    
    NSString *identifier = tableColumn.identifier;
    if ([identifier isEqualToString:@"MainCell"]) {
        SWSessionsTableCellView *cellView = [tableView makeViewWithIdentifier:identifier owner:self];
        
        // Get the title, possibly including highlighted search terms
        NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:cellData[kResultsTitleKey]];
        
        for (NSValue *highlightRangeObj in cellData[kResultsOffsetsKey][kResultsTitleKey]) {
            [title addAttribute:NSBackgroundColorAttributeName value:[[NSColor yellowColor] colorWithAlphaComponent:0.4] range:[highlightRangeObj rangeValue]];
        }
        
        cellView.titleField.attributedStringValue = title;
        cellView.sessionIdField.stringValue = [cellData[kResultsSessionNumberKey] description];
        cellView.trackField.stringValue = [NSString stringWithFormat:@"%@ (%@)", cellData[kResultsTrackKey], cellData[kResultsYearKey]];

        // Set the color of the detail blob
        int detailColorKey = [cellData[kResultsSessionNumberKey] intValue] / 100;
        NSColor *detailColor = standardColors[@(detailColorKey)];
        if (!detailColor) {
            detailColor = [NSColor lightGrayColor];
        }
        cellView.detailColor = detailColor;
        
        // Use the session description as a tooltip
        cellView.toolTip = cellData[kResultsDescriptionKey];
        return cellView;
    }
    return nil;
}

#pragma mark - Private methods

- (void)SW_fetchResults {
    NSMutableArray *mutableResults = [NSMutableArray array];

    bool isSearching = [self.searchTerm length] > 0;
    sqlite3_stmt *query = isSearching ? self.searchResultsQuery : self.allSessionsQuery;
    
    if (query && sqlite3_reset(query) == SQLITE_OK) {
        if (isSearching) {
            const char *searchTermUTF8String = [[self.searchTerm stringByAppendingString:@"*"] UTF8String];
            int result = sqlite3_bind_text(self.searchResultsQuery, 1, searchTermUTF8String, -1, SQLITE_TRANSIENT);
            if (result != SQLITE_OK) {
                return;
            }
        }
        while (sqlite3_step(query) == SQLITE_ROW) {
            int year = sqlite3_column_int(query, 0);
            int session_number = sqlite3_column_int(query, 1);
            const char *title = (const char*)sqlite3_column_text(query, 2);
            const char *description = (const char*)sqlite3_column_text(query, 3);
            const char *track = (const char*)sqlite3_column_text(query, 4);

            NSMutableDictionary *result = [NSMutableDictionary dictionary];
            result[kResultsSessionNumberKey] = @(session_number);
            result[kResultsTitleKey] = [NSString stringWithCString:title encoding:NSUTF8StringEncoding];
            result[kResultsDescriptionKey] = [NSString stringWithCString:description encoding:NSUTF8StringEncoding];
            result[kResultsTrackKey] = [NSString stringWithCString:track encoding:NSUTF8StringEncoding];
            result[kResultsYearKey] = @(year);
            
            if (isSearching) {
                NSMutableDictionary *offsets = [NSMutableDictionary dictionary];
                static NSArray *resultColumns;
                if (!resultColumns) {
                    resultColumns = @[kResultsSessionNumberKey, kResultsTitleKey, kResultsDescriptionKey];
                
                }
                NSString *offsetsString = [NSString stringWithCString:(const char*)sqlite3_column_text(query, 5) encoding:NSUTF8StringEncoding];
                NSArray *offsetComponents = [offsetsString componentsSeparatedByString:@" "];
                for (NSUInteger i = 0; i < [offsetComponents count]; i += 4) {
                    NSInteger columnIndex = [offsetComponents[i] integerValue];
                    NSInteger byteOffset = [offsetComponents[i+2] integerValue];
                    NSInteger byteLength = [offsetComponents[i+3] integerValue];
                    
                    NSString *key = resultColumns[columnIndex];
                    if (!offsets[key]) {
                        offsets[key] = [NSMutableArray array];
                    }
                    
                    NSUInteger charOffset = (NSUInteger)byteOffset;
                    NSUInteger endCharOffset = (NSUInteger)(byteOffset + byteLength);
                    NSUInteger charLength = (NSUInteger)byteLength;
                    
                    // Convert byte offset to character offset for title and description fields (which might contain non-ASCII UTF-8 characters)
                    if (key == kResultsTitleKey) {
                        charOffset = characterOffsetForByteOffsetInUTF8String(charOffset, title);
                        endCharOffset = characterOffsetForByteOffsetInUTF8String(endCharOffset, title);
                        charLength = endCharOffset - charOffset;
                    } else if (key == kResultsDescriptionKey) {
                        charOffset = characterOffsetForByteOffsetInUTF8String(charOffset, description);
                        endCharOffset = characterOffsetForByteOffsetInUTF8String(endCharOffset, description);
                        charLength = endCharOffset - charOffset;
                    }
                    NSRange range = NSMakeRange(charOffset, charLength);
                    [(NSMutableArray*)offsets[key] addObject:[NSValue valueWithRange:range]];
                }
                result[kResultsOffsetsKey] = offsets;
            }
            
            [mutableResults addObject:result];
        }
    }
    
    self.results = [NSArray arrayWithArray:mutableResults];
}

- (void)SW_handleDoubleClick:(id)sender {
    [self SW_launchWebsiteForRow:self.tableView.clickedRow];
}

- (void)SW_launchWebsiteForRow:(NSInteger)row {
    NSDictionary *data = self.results[row];
    NSNumber *sessionNumber = data[kResultsSessionNumberKey];
    
    NSString *urlString = [NSString stringWithFormat:@"https://developer.apple.com/videos/wwdc/%@/?id=%@", data[kResultsYearKey], sessionNumber];
    NSURL *url = [NSURL URLWithString:urlString];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
