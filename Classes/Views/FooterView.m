//
//  FooterView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/12/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "FooterView.h"

@implementation FooterView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    //// Color Declarations
    NSColor* strokeColor = [NSColor colorWithCalibratedRed: 0.314 green: 0.314 blue: 0.314 alpha: 1];
    NSColor* topGradientColor = [NSColor colorWithCalibratedRed: 0.188 green: 0.188 blue: 0.188 alpha: 1];
    NSColor* bottomGradientColor = [NSColor colorWithCalibratedRed: 0.122 green: 0.122 blue: 0.122 alpha: 1];

    //// Gradient Declarations
    NSGradient* toolbarGradient = [[NSGradient alloc] initWithStartingColor: topGradientColor endingColor: bottomGradientColor];

    //// Shadow Declarations
    NSShadow* topInnerShadow = [[NSShadow alloc] init];
    [topInnerShadow setShadowColor: strokeColor];
    [topInnerShadow setShadowOffset: NSMakeSize(0.1, -1.1)];
    [topInnerShadow setShadowBlurRadius: 0];

    //// Rectangle Drawing
    NSBezierPath* rectanglePath = [NSBezierPath bezierPathWithRect: NSMakeRect(0, 0, 360, 36)];
    [toolbarGradient drawInBezierPath: rectanglePath angle: -90];

    ////// Rectangle Inner Shadow
    NSRect rectangleBorderRect = NSInsetRect([rectanglePath bounds], -topInnerShadow.shadowBlurRadius, -topInnerShadow.shadowBlurRadius);
    rectangleBorderRect = NSOffsetRect(rectangleBorderRect, -topInnerShadow.shadowOffset.width, -topInnerShadow.shadowOffset.height);
    rectangleBorderRect = NSInsetRect(NSUnionRect(rectangleBorderRect, [rectanglePath bounds]), -1, -1);

    NSBezierPath* rectangleNegativePath = [NSBezierPath bezierPathWithRect: rectangleBorderRect];
    [rectangleNegativePath appendBezierPath: rectanglePath];
    [rectangleNegativePath setWindingRule: NSEvenOddWindingRule];

    [NSGraphicsContext saveGraphicsState];
    {
        NSShadow* topInnerShadowWithOffset = [topInnerShadow copy];
        CGFloat xOffset = topInnerShadowWithOffset.shadowOffset.width + round(rectangleBorderRect.size.width);
        CGFloat yOffset = topInnerShadowWithOffset.shadowOffset.height;
        topInnerShadowWithOffset.shadowOffset = NSMakeSize(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset));
        [topInnerShadowWithOffset set];
        [[NSColor grayColor] setFill];
        [rectanglePath addClip];
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy: -round(rectangleBorderRect.size.width) yBy: 0];
        [[transform transformBezierPath: rectangleNegativePath] fill];
    }
    [NSGraphicsContext restoreGraphicsState];
}

@end
