//
//  HeaderView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/19/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "HeaderView.h"

#import "NSColor+Hex.h"


@implementation HeaderView

- (void)drawRect:(NSRect)dirtyRect
{
    // Abstracted attributes.
    CGFloat cornerRadius = 5;

    // Declare our colors first.
    NSColor* topColor = [NSColor colorWithHex:@"#464646"];
    NSColor* bottomColor = [NSColor colorWithHex:@"#262626"];
    NSColor* highlightColor = [NSColor colorWithHex:@"#555"];

    // We're only drawing the left side of the two-tone header.
    NSRect rect = NSMakeRect(0, 0, 38, 34);
    NSRect innerRect = NSInsetRect(rect, cornerRadius, cornerRadius);
    NSBezierPath* path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(NSMinX(rect), NSMinY(rect))];
    [path lineToPoint:NSMakePoint(NSMaxX(rect), NSMinY(rect))];
    [path lineToPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect))];
    [path appendBezierPathWithArcWithCenter: NSMakePoint(NSMinX(innerRect), NSMaxY(innerRect)) radius:cornerRadius startAngle:90 endAngle:180];
    [path closePath];

    NSGradient* gradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:bottomColor];
    [gradient drawInBezierPath:path angle:-90];

    // Draw a box for the highlight too.
    NSRect highlightRect = NSMakeRect(4, 33.5, 33, 0.5);
    [highlightColor setFill];
    NSRectFill(highlightRect);

    // Draw a "faked" shadow to separate the two sides of the footer.
    [bottomColor setFill];
    NSRectFill(NSMakeRect(37, 0, 1, 33.5));

    [super drawRect:dirtyRect];
}

@end
