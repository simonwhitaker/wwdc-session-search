//
//  SWSessionsTableCellView.h
//  WWDC Video Search
//
//  Created by Simon Whitaker on 27/12/2013.
//  Copyright (c) 2013 Simon Whitaker. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SWSessionsTableCellView : NSTableCellView

@property(assign) IBOutlet NSTextField *titleField;
@property(assign) IBOutlet NSTextField *trackField;
@property(assign) IBOutlet NSTextField *sessionIdField;

@end
