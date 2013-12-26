//
//  SWMainWindowController.m
//  WWDC Video Search
//
//  Created by Simon Whitaker on 26/12/2013.
//  Copyright (c) 2013 Simon Whitaker. All rights reserved.
//

#import "SWMainWindowController.h"

@implementation SWMainWindowController

- (void)keyDown:(NSEvent *)theEvent {
    NSLog(@"Got keyDown event: %@", theEvent);
    
    unichar keyCharacter = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    if (self.tableView.selectedRow >= 0 && (keyCharacter == NSEnterCharacter || keyCharacter == NSCarriageReturnCharacter)) {
        
        NSTableColumn *sessionIdColumn = [self.tableView tableColumnWithIdentifier:@"session"];
        NSNumber *sessionId = [self.tableView.dataSource tableView:self.tableView objectValueForTableColumn:sessionIdColumn row:self.tableView.selectedRow];
        
        NSString *urlString = [NSString stringWithFormat:@"https://developer.apple.com/wwdc/videos/index.php?id=%@", sessionId];
        NSURL *url = [NSURL URLWithString:urlString];
        [[NSWorkspace sharedWorkspace] openURL:url];
    } else {
        // Pass on the key event
        [self interpretKeyEvents:@[theEvent]];
    }
}

@end
