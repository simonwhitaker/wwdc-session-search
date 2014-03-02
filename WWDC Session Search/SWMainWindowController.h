//
//  SWMainWindowController.h
//  WWDC Video Search
//
//  Created by Simon Whitaker on 26/12/2013.
//  Copyright (c) 2013 Simon Whitaker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SWLocalAssetController.h"

@interface SWMainWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic) NSString *searchTerm;
@property (nonatomic) NSTableView *tableView;
@property (nonatomic) SWLocalAssetController *localAssetController;

- (IBAction)openLocalSDVideoAsset:(id)sender;
- (IBAction)openLocalHDVideoAsset:(id)sender;
- (IBAction)openLocalPDFAsset:(id)sender;

@end
