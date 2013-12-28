//
//  SWSessionsTableCellView.m
//  WWDC Video Search
//
//  Created by Simon Whitaker on 27/12/2013.
//  Copyright (c) 2013 Simon Whitaker. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SWSessionsTableCellView.h"

const CGFloat kDetailSize = 10.0;

@interface SWSessionsTableCellView()
@property (nonatomic) CAShapeLayer *shapeLayer;
@end

@implementation SWSessionsTableCellView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self SW_commonInit];
    }
    return self;
}

- (void)setDetailColor:(NSColor *)detailColor {
    if (detailColor != _detailColor) {
        _detailColor = detailColor;
        self.shapeLayer.fillColor = [_detailColor CGColor];
    }
}

- (void)layout {
    [super layout];
    self.shapeLayer.position = CGPointMake(self.titleField.frame.origin.x / 2, self.frame.size.height / 2);
}

- (void)SW_commonInit {
    self.wantsLayer = YES;
    self.detailColor = [NSColor lightGrayColor];
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddEllipseInRect(path, &CGAffineTransformIdentity, CGRectMake(0, 0, 10, 10));
    
    
    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    shapeLayer.bounds = CGPathGetBoundingBox(path);
    shapeLayer.path = path;
    shapeLayer.fillColor = [self.detailColor CGColor];
    
    self.layer = [CALayer layer];
    [self.layer addSublayer:shapeLayer];
    self.shapeLayer = shapeLayer;
    
    CGPathRelease(path);
}

@end
