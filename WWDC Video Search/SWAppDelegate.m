//
//  SWAppDelegate.m
//  WWDC Video Search
//
//  Created by Simon Whitaker on 26/12/2013.
//  Copyright (c) 2013 Netcetera. All rights reserved.
//

#import "SWAppDelegate.h"
#import "SWSessionsDataSource.h"

@interface SWAppDelegate() <NSTextFieldDelegate, NSTextDelegate>
@property (nonatomic) SWSessionsDataSource *sessionsDataSource;
@end

@implementation SWAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Configure the table view's data source
    self.sessionsDataSource = [[SWSessionsDataSource alloc] initWithSQLiteFilePath:[[NSBundle mainBundle] pathForResource:@"sessions.sqlite3" ofType:nil]];
    self.tableView.dataSource = self.sessionsDataSource;
    
    self.searchField.delegate = self;
}

#pragma mark - NSTextFieldDelegate methods

- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextView *textView = (NSTextView*)(notification.userInfo[@"NSFieldEditor"]);
    self.sessionsDataSource.searchTerm = textView.textStorage.string;
    [self.tableView reloadData];
}

@end
