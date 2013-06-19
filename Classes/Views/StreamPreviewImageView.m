//
//  StreamPreviewImageView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/18/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "StreamPreviewImageView.h"

#import "NSImage+MGCropExtensions.h"

@implementation StreamPreviewImageView

- (void)drawRect:(NSRect)dirtyRect
{
    // Abstracted attributes.
    CGFloat cornerRadius = 2;

    // Draw the inner rectangle with the bottom rounded corners.
    NSRect initialRect = NSMakeRect(0, 0, 304, 85);
    NSRect innerRect = NSInsetRect(initialRect, cornerRadius, cornerRadius);
    NSBezierPath* path = [NSBezierPath bezierPath];
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(innerRect), NSMinY(innerRect)) radius:cornerRadius startAngle:180 endAngle:270];
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(innerRect), NSMinY(innerRect)) radius:cornerRadius startAngle:270 endAngle:360];
    [path lineToPoint:NSMakePoint(NSMaxX(initialRect), NSMaxY(initialRect))];
    [path lineToPoint:NSMakePoint(NSMinX(initialRect), NSMaxY(initialRect))];
    [path closePath];
    [[NSColor blackColor] setFill];
    [path fill];

    // Crop the preview image, because squishy images suck.
    NSImage *croppedImage = [self.image imageToFitSize:NSMakeSize(304, 85) method:MGImageResizeCropStart];
    [croppedImage drawInRect:innerRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];

    // Draw the title rectangle with the same bottom rounded corners and a
    // translucent black background for the title text to sit on.
    NSColor* titleBackgroundColor = [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.8];
    NSRect titleRect = NSMakeRect(0, 0, 304, 48);
    NSRect titleInnerRect = NSInsetRect(titleRect, cornerRadius, cornerRadius);
    NSBezierPath* titlePath = [NSBezierPath bezierPath];
    [titlePath appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(titleInnerRect), NSMinY(titleInnerRect)) radius:cornerRadius startAngle:180 endAngle:270];
    [titlePath appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(titleInnerRect), NSMinY(titleInnerRect)) radius:cornerRadius startAngle:270 endAngle:360];
    [titlePath lineToPoint:NSMakePoint(NSMaxX(titleRect), NSMaxY(titleRect))];
    [titlePath lineToPoint:NSMakePoint(NSMinX(titleRect), NSMaxY(titleRect))];
    [titlePath closePath];
    [titleBackgroundColor setFill];
    [titlePath fill];
}

@end
