//
//  SWLocalAssetController.m
//  WWDC Session Search
//
//  Created by Simon Whitaker on 02/03/2014.
//  Copyright (c) 2014 Simon Whitaker. All rights reserved.
//

#import "SWLocalAssetController.h"

NSString *const SWLocalAssetTypeSDVideoKey = @"SDVideo";
NSString *const SWLocalAssetTypeHDVideoKey = @"HDVideo";
NSString *const SWLocalAssetTypePDFKey = @"PDF";
NSString *const SWLocalAssetControllerDidGetAssetsNotification = @"SWLocalAssetControllerDidGetAssetsNotification";

static NSString *const kURIPDF = @"com.adobe.pdf";
static NSString *const kURIMovie = @"com.apple.quicktime-movie";

@interface SWLocalAssetController()
@property (nonatomic) NSMutableDictionary *filePathRegister;
@property (nonatomic) NSMetadataQuery *query;
@end

@implementation SWLocalAssetController

- (id)init {
    self = [super init];
    if (self) {
        _query = [[NSMetadataQuery alloc] init];
        _query.predicate = [NSPredicate predicateWithFormat:@"kMDItemWhereFroms LIKE 'http://devstreaming.apple.com/*wwdc*' || kMDItemWhereFroms LIKE 'http://adcdownload.apple.com/*wwdc*' || kMDItemWhereFroms LIKE 'http://developer.apple.com/*/wwdc_2012/*'"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sw_handleSearchCompletion:) name:NSMetadataQueryDidFinishGatheringNotification object:_query];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sw_handleSearchUpdates:) name:NSMetadataQueryDidUpdateNotification object:_query];
        
        [_query startQuery];
    }
    return self;
}

- (NSDictionary *)filePathsForSession:(NSUInteger)sessionId year:(NSUInteger)year {
    NSDictionary *pathsForYear = self.filePathRegister[@(year)];
    if (pathsForYear) {
        return pathsForYear[@(sessionId)];
    }
    return nil;
}

- (void)sw_handleSearchUpdates:(NSNotification*)notification {
    NSLog(@"Search got updates");
    [self.query disableUpdates];
    [self sw_registerLocalItems];
    [self.query enableUpdates];
}

- (void)sw_handleSearchCompletion:(NSNotification*)notification {
    NSLog(@"Search completed");
    [self.query disableUpdates];
    [self sw_registerLocalItems];
    [self.query enableUpdates];
}

- (void)sw_registerLocalItems {
    NSLog(@"Registering %lu local item(s)", (unsigned long)[self.query resultCount]);
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionary];
    for (NSUInteger i = 0; i < [self.query resultCount]; i++) {
        [self sw_registerLocalItem:[self.query resultAtIndex:i] inMutableDictionary:mutableDictionary];
    }
    self.filePathRegister = mutableDictionary;
}

- (void)sw_registerLocalItem:(NSMetadataItem*)item inMutableDictionary:(NSMutableDictionary*)mutableDictionary {
    static NSDictionary *regexps;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regexps = @{
                    // Maps regular expressions to the year they match. Each regular expression should have one matching group of (\\d+) that captures the session ID
                    [NSRegularExpression regularExpressionWithPattern:@"//developer.apple.com/devcenter/download.action.+session_(\\d+)" options:NSRegularExpressionCaseInsensitive error:nil]: @2012,
                    [NSRegularExpression regularExpressionWithPattern:@"//adcdownload.apple.com/.+session_(\\d+)" options:NSRegularExpressionCaseInsensitive error:nil]: @2012,
                    [NSRegularExpression regularExpressionWithPattern:@"//devstreaming.apple.com/videos/wwdc/2013/\\w+/(\\d+)" options:NSRegularExpressionCaseInsensitive error:nil]: @2013,
                    };
    });
    
    NSString *sourceURLString = [(NSArray*)[item valueForAttribute:(NSString*)kMDItemWhereFroms] firstObject];
    NSRange sourceURLStringRange = NSMakeRange(0, [sourceURLString length]);
    __block bool matchedRegexp = false;
    [regexps enumerateKeysAndObjectsUsingBlock:^(NSRegularExpression *regexp, NSNumber *year, BOOL *stop) {
        NSTextCheckingResult *result = [regexp firstMatchInString:sourceURLString options:0 range:sourceURLStringRange];
        if (result) {
            *stop = YES;
            matchedRegexp = true;
            
            NSNumber *sessionId = @([[sourceURLString substringWithRange:[result rangeAtIndex:1]] integerValue]);
            NSString *path = [item valueForAttribute:(NSString*)kMDItemPath];
            NSString *itemTypeKey;
            NSString *itemContentType = [item valueForAttribute:(NSString*)kMDItemContentType];
            if ([itemContentType isEqualToString:kURIPDF]) {
                itemTypeKey = SWLocalAssetTypePDFKey;
            } else if ([itemContentType isEqualToString:kURIMovie]) {
                NSInteger pixelHeight = [[item valueForAttribute:(NSString*)kMDItemPixelHeight] integerValue];
                if (pixelHeight >= 720) {
                    itemTypeKey = SWLocalAssetTypeHDVideoKey;
                } else {
                    itemTypeKey = SWLocalAssetTypeSDVideoKey;
                }
            }
            if (!itemTypeKey) {
                NSLog(@"Error: couldn't determine type of item at %@", path);
                return;
            }
            
            NSMutableDictionary *pathsForYear = mutableDictionary[year];
            if (!pathsForYear) {
                mutableDictionary[year] = [NSMutableDictionary dictionary];
                pathsForYear = mutableDictionary[year];
            }
            NSMutableDictionary *pathsForSession = pathsForYear[sessionId];
            if (!pathsForSession) {
                pathsForYear[sessionId] = [NSMutableDictionary dictionary];
                pathsForSession = pathsForYear[sessionId];
            }
            pathsForSession[itemTypeKey] = path;
        }
    }];
    
    if (!matchedRegexp) {
        NSLog(@"Error, didn't match regexp: %@", [(NSArray*)[item valueForAttribute:(NSString*)kMDItemWhereFroms] firstObject]);
    }
}

@end
