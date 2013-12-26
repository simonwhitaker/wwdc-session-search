//
//  SWSessionsDataSource.h
//  WWDC Video Search
//
//  Created by Simon Whitaker on 26/12/2013.
//  Copyright (c) 2013 Simon Whitaker. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SWSessionsDataSource : NSObject <NSTableViewDataSource>

@property (nonatomic) NSString *searchTerm;

- (id)initWithSQLiteFilePath:(NSString*)dbFilePath;

@end
