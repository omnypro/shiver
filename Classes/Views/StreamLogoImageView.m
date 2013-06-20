//
//  StreamLogoImageView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/12/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "StreamLogoImageView.h"

CGFloat const StreamImageViewCornerRadius = 0;
CGFloat const StreamImageViewImageInset = 1.0;
CGFloat const StreamImageViewHighlightCurveStartXOffset = 5.0;
CGFloat const StreamImageViewHighlightCurveEndYOffset = 5.0;

@implementation StreamLogoImageView

- (void)drawRect:(NSRect)dirtyRect
{
    [NSGraphicsContext saveGraphicsState];

    NSShadow* shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.5]];
    [shadow setShadowOffset: NSMakeSize(0.0, -3.0)];
    [shadow setShadowBlurRadius:6];
    [shadow set];

    NSRect drawingBounds = NSMakeRect(NSMinX(self.bounds), floor(NSMinY(self.bounds) + 1.0), NSWidth(self.bounds), floor(NSHeight(self.bounds) - 1.0));
    NSBezierPath *outerClip = [NSBezierPath bezierPathWithRoundedRect:drawingBounds xRadius:StreamImageViewCornerRadius yRadius:StreamImageViewCornerRadius];
    static NSGradient *backingGrad = nil;
    if (backingGrad == nil) {
        NSColor *startColor = [NSColor colorWithCalibratedWhite:(23.0/255.0) alpha:1.0];
        NSColor *endColor = [NSColor colorWithCalibratedWhite:(36.0/255.0) alpha:1.0];
        backingGrad = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
    }
    [backingGrad drawInBezierPath:outerClip angle:90.0];

    NSRect imageRect = NSInsetRect(drawingBounds, StreamImageViewImageInset, StreamImageViewImageInset);
    [self.image drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];

    NSBezierPath *highlightPath = [NSBezierPath bezierPath];
    [highlightPath moveToPoint:NSMakePoint(floor(NSMinX(imageRect) + StreamImageViewHighlightCurveStartXOffset), NSMinY(imageRect))];
    NSPoint controlPoint = NSMakePoint(NSMidX(imageRect), NSMidY(imageRect));
    [highlightPath curveToPoint:NSMakePoint(NSMaxX(imageRect), floor(NSMaxY(imageRect) - StreamImageViewHighlightCurveEndYOffset)) controlPoint1:controlPoint controlPoint2:controlPoint];

    [highlightPath lineToPoint:NSMakePoint(NSMaxX(imageRect), NSMaxY(imageRect))];
    [highlightPath lineToPoint:NSMakePoint(NSMinX(imageRect), NSMaxY(imageRect))];
    [highlightPath lineToPoint:NSMakePoint(NSMinX(imageRect), NSMinY(imageRect))];
    [highlightPath closePath];

    static NSGradient *highlightGrad = nil;
    if (highlightGrad == nil) {
        NSColor *startColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.2];
        NSColor *endColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.0];
        highlightGrad = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
    }

    [highlightGrad drawInBezierPath:highlightPath angle:270.0];

    [NSGraphicsContext restoreGraphicsState];
}

@end
