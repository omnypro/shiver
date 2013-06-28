//
//  FooterView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/12/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "FooterView.h"

#import "NSColor+Hex.h"

@implementation FooterView

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect frame = dirtyRect;

    // Declare our colors first. There's a lot of them.
    NSColor *topColor = [NSColor colorWithHex:@"#343434"];;
    NSColor *bottomColor = [NSColor colorWithHex:@"#141414"];
    NSColor *highlightColor = [NSColor colorWithHex:@"#3F3F40"];

    // Draw the left side of the two-tone footer first.
    NSRect leftRect = NSMakeRect(0, 0, NSWidth(frame), NSHeight(frame));
    NSRect leftHighlightRect = NSMakeRect(0, NSHeight(frame) - 2, NSWidth(frame), 1);
    NSGradient *leftGradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:bottomColor];
    [leftGradient drawInRect:leftRect angle:-90];
    [highlightColor setFill];
    NSRectFill(leftHighlightRect);

    [super drawRect:dirtyRect];
}

@end
