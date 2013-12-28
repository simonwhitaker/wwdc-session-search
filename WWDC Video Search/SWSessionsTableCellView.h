//
//  SWSessionsTableCellView.h
//  WWDC Video Search
//
//  Created by Simon Whitaker on 27/12/2013.
//  Copyright (c) 2013 Simon Whitaker. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SWSessionsTableCellView : NSTableCellView

@property (nonatomic, weak) IBOutlet NSTextField *titleField;
@property (nonatomic, weak) IBOutlet NSTextField *trackField;
@property (nonatomic, weak) IBOutlet NSTextField *sessionIdField;
@property (nonatomic, strong) NSColor *detailColor;

@end
