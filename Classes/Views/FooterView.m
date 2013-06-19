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
    // Declare our colors and gradients first. There's a lot of them.
    NSColor *leftTopColor = [NSColor colorWithHex:@"#343434"];;
    NSColor *leftBottomColor = [NSColor colorWithHex:@"#141414"];
    NSColor *rightTopColor = [NSColor colorWithHex:@"#E0E0E1"];
    NSColor *rightBottomColor = [NSColor colorWithHex:@"#C0C0C6"];
    NSColor *leftHighlightColor = [NSColor colorWithHex:@"#3F3F40"];
    NSGradient *leftGradient = [[NSGradient alloc] initWithStartingColor:leftTopColor endingColor:leftBottomColor];
    NSGradient *rightGradient = [[NSGradient alloc] initWithStartingColor:rightTopColor endingColor:rightBottomColor];

    // Draw the left side of the two-tone footer first.
    NSBezierPath* leftPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, 38, 36)];
    NSBezierPath* leftHighlightPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 35, 37, 1)];
    [leftGradient drawInBezierPath:leftPath angle: -90];
    [leftHighlightColor setFill];
    [leftHighlightPath fill];

    // Draw the right side of the two-tone footer.
    NSBezierPath* rightPath = [NSBezierPath bezierPathWithRect:NSMakeRect(38, 0, 282, 36)];
    NSBezierPath* rightHighlightPath = [NSBezierPath bezierPathWithRect:NSMakeRect(38, 35, 282, 1)];
    [rightGradient drawInBezierPath: rightPath angle: -90];
    [[NSColor whiteColor] setFill];
    [rightHighlightPath fill];

    // Draw a "faked" shadow to separate the two sides of the footer.
    NSBezierPath* rectanglePath = [NSBezierPath bezierPathWithRect:NSMakeRect(37, 0, 1, 36)];
    [[NSColor blackColor] setFill];
    [rectanglePath fill];

    [super drawRect:dirtyRect];
}

@end
