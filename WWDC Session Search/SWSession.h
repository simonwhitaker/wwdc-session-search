//
//  SWSession.h
//  WWDC Session Search
//
//  Created by Simon Whitaker on 02/03/2014.
//  Copyright (c) 2014 Simon Whitaker. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SWSession : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *track;
@property (nonatomic, copy) NSString *sessionDescription;
@property (nonatomic) NSUInteger year;
@property (nonatomic) NSUInteger number;

@end
