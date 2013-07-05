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
    [super drawRect:dirtyRect];

    // Declare our colors first. There's a lot of them.
    NSColor *topColor = [NSColor colorWithHex:@"#2f2f2f"];;
    NSColor *bottomColor = [NSColor colorWithHex:@"#141414"];
    NSColor *highlightColor = [NSColor colorWithHex:@"#3F3F40"];

    // Draw the left side of the two-tone footer first.
    NSRect leftRect = NSMakeRect(0, 0, 320, 32);
    NSRect leftHighlightRect = NSMakeRect(0, 31, 320, 1);
    NSGradient *leftGradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:bottomColor];
    [leftGradient drawInRect:leftRect angle:-90];
    [highlightColor setFill];
    NSRectFill(leftHighlightRect);
}

- (BOOL)isOpaque
{
    return YES;
}

@end
