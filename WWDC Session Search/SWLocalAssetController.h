//
//  SWLocalAssetController.h
//  WWDC Session Search
//
//  Created by Simon Whitaker on 02/03/2014.
//  Copyright (c) 2014 Simon Whitaker. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const SWLocalAssetTypeSDVideoKey;
extern NSString *const SWLocalAssetTypeHDVideoKey;
extern NSString *const SWLocalAssetTypePDFKey;
extern NSString *const SWLocalAssetControllerDidGetAssetsNotification;

/**
 * SWLocalAssetController keeps tracks of WWDC session assets (PDFs and movies) on the local file system.
 */
@interface SWLocalAssetController : NSObject

- (NSDictionary*)assetPathsForSession:(NSUInteger)sessionId year:(NSUInteger)year;
- (NSString*)assetPathForSession:(NSUInteger)sessionId year:(NSUInteger)year assetType:(NSString*)assetType;

@end
