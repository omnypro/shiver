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
    NSRect frame = dirtyRect;

    // Declare our colors first.
    NSColor *topColor = [NSColor colorWithHex:@"#F4F4F5"];
    NSColor *bottomColor = [NSColor colorWithHex:@"#C4C4C5"];
    NSColor *highlightColor = [NSColor colorWithHex:@"#FFF"];

    // We're only drawing the left side of the two-tone header.
    NSRect rect = NSMakeRect(0, 0, NSWidth(frame), 32);
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:bottomColor];
    [gradient drawInRect:rect angle:-90];

    // Draw boxes for the highlight and shadow too.
    NSRect highlightRect = NSMakeRect(0, 31, NSWidth(frame), 1);
    [highlightColor setFill];
    NSRectFill(highlightRect);

    [super drawRect:dirtyRect];
}

@end
