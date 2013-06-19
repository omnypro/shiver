//
//  FooterView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/12/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "FooterView.h"

@implementation FooterView

- (void)drawRect:(NSRect)dirtyRect
{
    //// Color Declarations
    NSColor* footerLeftTopColor = [NSColor colorWithCalibratedRed: 0.204 green: 0.204 blue: 0.204 alpha: 1];
    NSColor* footerLeftBottomColor = [NSColor colorWithCalibratedRed: 0.078 green: 0.078 blue: 0.078 alpha: 1];
    NSColor* footerRightTopColor = [NSColor colorWithCalibratedRed: 0.941 green: 0.941 blue: 0.945 alpha: 1];
    NSColor* footerRightBottomColor = [NSColor colorWithCalibratedRed: 0.859 green: 0.863 blue: 0.886 alpha: 1];
    NSColor* footerLeftInnerShadowColor = [NSColor colorWithCalibratedRed: 0.333 green: 0.333 blue: 0.333 alpha: 1];

    //// Gradient Declarations
    NSGradient* footerLeftGradient = [[NSGradient alloc] initWithStartingColor: footerLeftTopColor endingColor: footerLeftBottomColor];
    NSGradient* footerRightGradient = [[NSGradient alloc] initWithStartingColor: footerRightTopColor endingColor: footerRightBottomColor];

    //// Shadow Declarations
    NSShadow* footerLeftInnerShadow = [[NSShadow alloc] init];
    [footerLeftInnerShadow setShadowColor: footerLeftInnerShadowColor];
    [footerLeftInnerShadow setShadowOffset: NSMakeSize(0.1, -1.1)];
    [footerLeftInnerShadow setShadowBlurRadius: 0];
    NSShadow* footerRightInnerShadow = [[NSShadow alloc] init];
    [footerRightInnerShadow setShadowColor: [NSColor whiteColor]];
    [footerRightInnerShadow setShadowOffset: NSMakeSize(0.1, -1.1)];
    [footerRightInnerShadow setShadowBlurRadius: 0];

    //// Footer (Left) Drawing
    NSBezierPath* footerLeftPath = [NSBezierPath bezierPathWithRect: NSMakeRect(0, 0, 38, 36)];
    [footerLeftGradient drawInBezierPath: footerLeftPath angle: -90];

    ////// Footer (Left) Inner Shadow
    NSRect footerLeftBorderRect = NSInsetRect([footerLeftPath bounds], -footerLeftInnerShadow.shadowBlurRadius, -footerLeftInnerShadow.shadowBlurRadius);
    footerLeftBorderRect = NSOffsetRect(footerLeftBorderRect, -footerLeftInnerShadow.shadowOffset.width, -footerLeftInnerShadow.shadowOffset.height);
    footerLeftBorderRect = NSInsetRect(NSUnionRect(footerLeftBorderRect, [footerLeftPath bounds]), -1, -1);

    NSBezierPath* footerLeftNegativePath = [NSBezierPath bezierPathWithRect: footerLeftBorderRect];
    [footerLeftNegativePath appendBezierPath: footerLeftPath];
    [footerLeftNegativePath setWindingRule: NSEvenOddWindingRule];

    [NSGraphicsContext saveGraphicsState];
    {
        NSShadow* footerLeftInnerShadowWithOffset = [footerLeftInnerShadow copy];
        CGFloat xOffset = footerLeftInnerShadowWithOffset.shadowOffset.width + round(footerLeftBorderRect.size.width);
        CGFloat yOffset = footerLeftInnerShadowWithOffset.shadowOffset.height;
        footerLeftInnerShadowWithOffset.shadowOffset = NSMakeSize(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset));
        [footerLeftInnerShadowWithOffset set];
        [[NSColor grayColor] setFill];
        [footerLeftPath addClip];
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy: -round(footerLeftBorderRect.size.width) yBy: 0];
        [[transform transformBezierPath: footerLeftNegativePath] fill];
    }
    [NSGraphicsContext restoreGraphicsState];

    // Footer (Right) Drawing
    NSBezierPath* footerRightPath = [NSBezierPath bezierPathWithRect: NSMakeRect(38, 0, 282, 36)];
    [footerRightGradient drawInBezierPath: footerRightPath angle: -90];

    // Footer (Right) Inner Shadow
    NSRect footerRightBorderRect = NSInsetRect([footerRightPath bounds], -footerRightInnerShadow.shadowBlurRadius, -footerRightInnerShadow.shadowBlurRadius);
    footerRightBorderRect = NSOffsetRect(footerRightBorderRect, -footerRightInnerShadow.shadowOffset.width, -footerRightInnerShadow.shadowOffset.height);
    footerRightBorderRect = NSInsetRect(NSUnionRect(footerRightBorderRect, [footerRightPath bounds]), -1, -1);

    NSBezierPath* footerRightNegativePath = [NSBezierPath bezierPathWithRect: footerRightBorderRect];
    [footerRightNegativePath appendBezierPath: footerRightPath];
    [footerRightNegativePath setWindingRule: NSEvenOddWindingRule];

    [NSGraphicsContext saveGraphicsState];
    {
        NSShadow* footerRightInnerShadowWithOffset = [footerRightInnerShadow copy];
        CGFloat xOffset = footerRightInnerShadowWithOffset.shadowOffset.width + round(footerRightBorderRect.size.width);
        CGFloat yOffset = footerRightInnerShadowWithOffset.shadowOffset.height;
        footerRightInnerShadowWithOffset.shadowOffset = NSMakeSize(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset));
        [footerRightInnerShadowWithOffset set];
        [[NSColor grayColor] setFill];
        [footerRightPath addClip];
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy: -round(footerRightBorderRect.size.width) yBy: 0];
        [[transform transformBezierPath: footerRightNegativePath] fill];
    }
    [NSGraphicsContext restoreGraphicsState];

    //// Rectangle Drawing
    NSBezierPath* rectanglePath = [NSBezierPath bezierPathWithRect: NSMakeRect(37, 0, 1, 36)];
    [[NSColor blackColor] setFill];
    [rectanglePath fill];
}

@end
