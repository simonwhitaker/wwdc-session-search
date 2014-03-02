//
//  SWAppDelegate.m
//  WWDC Video Search
//
//  Created by Simon Whitaker on 26/12/2013.
//  Copyright (c) 2013 Simon Whitaker. All rights reserved.
//

#import "SWAppDelegate.h"
#import "SWMainWindowController.h"
#import "SWLocalAssetController.h"

@interface SWAppDelegate() <NSTextFieldDelegate, NSTextDelegate>
@property (nonatomic) SWMainWindowController *mainWindowController;
@property (nonatomic) SWLocalAssetController *localAssetController;
@end

@implementation SWAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Configure the search field
    self.searchField.delegate = self;
    [self.searchField becomeFirstResponder];
    
    self.localAssetController = [[SWLocalAssetController alloc] init];
    
    // Configure the main window controller
    self.mainWindowController = [[SWMainWindowController alloc] initWithWindow:self.window];
    self.mainWindowController.tableView = self.tableView;
    self.mainWindowController.localAssetController = self.localAssetController;
}

#pragma mark - NSTextFieldDelegate methods

- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextView *textView = (NSTextView*)(notification.userInfo[@"NSFieldEditor"]);
    self.mainWindowController.searchTerm = textView.textStorage.string;
}

@end
