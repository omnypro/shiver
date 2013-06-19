//
//  HeaderView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/19/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "HeaderView.h"

#import "NSColor+Hex.h"

const CGFloat cornerRadius = 5;

@implementation HeaderView

- (void)drawRect:(NSRect)dirtyRect
{
    // Declare our colors first.
    NSColor* topColor = [NSColor colorWithHex:@"#545353"];
    NSColor* bottomColor = [NSColor colorWithHex:@"#2A2A2A"];
    NSColor* highlightColor = [NSColor colorWithHex:@"#838282"];

    // Gradient and shadow next.
    NSGradient* gradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:bottomColor];

    // We're only drawing the left side of the two-tone header.
    NSRect rect = NSMakeRect(0, 0, 38, 34);
    NSRect innerRect = NSInsetRect(rect, cornerRadius, cornerRadius);
    NSBezierPath* path = [NSBezierPath bezierPath];
    [path moveToPoint: NSMakePoint(NSMinX(rect), NSMinY(rect))];
    [path lineToPoint: NSMakePoint(NSMaxX(rect), NSMinY(rect))];
    [path lineToPoint: NSMakePoint(NSMaxX(rect), NSMaxY(rect))];
    [path appendBezierPathWithArcWithCenter: NSMakePoint(NSMinX(innerRect), NSMaxY(innerRect)) radius: cornerRadius startAngle: 90 endAngle: 180];
    [path closePath];
    [gradient drawInBezierPath: path angle: -90];

    // Draw a box for the highlight too.
    NSRect highlightRect = NSMakeRect(4, 33.5, 33, 0.5);
    [highlightColor setFill];
    NSRectFill(highlightRect);

    // Draw a "faked" shadow to separate the two sides of the footer.
    [[NSColor colorWithHex:@"#333333"] setFill];
    NSRectFill(NSMakeRect(37, 0, 1, 33.5));

    [super drawRect:dirtyRect];
}

@end
