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
    // Declare our colors first. There's a lot of them.
    NSColor *leftTopColor = [NSColor colorWithHex:@"#343434"];;
    NSColor *leftBottomColor = [NSColor colorWithHex:@"#141414"];
    NSColor *rightTopColor = [NSColor colorWithHex:@"#E0E0E1"];
    NSColor *rightBottomColor = [NSColor colorWithHex:@"#C0C0C6"];
    NSColor *leftHighlightColor = [NSColor colorWithHex:@"#3F3F40"];

    // Draw the left side of the two-tone footer first.
    NSRect leftRect = NSMakeRect(0, 0, 38, 36);
    NSRect leftHighlightRect = NSMakeRect(0, 35, 37, 1);
    NSGradient *leftGradient = [[NSGradient alloc] initWithStartingColor:leftTopColor endingColor:leftBottomColor];
    [leftGradient drawInRect:leftRect angle:-90];
    [leftHighlightColor setFill];
    NSRectFill(leftHighlightRect);

    // Draw the right side of the two-tone footer.
    NSRect rightRect = NSMakeRect(38, 0, 282, 36);
    NSRect rightHighlightRect = NSMakeRect(38, 35, 282, 1);
    NSGradient *rightGradient = [[NSGradient alloc] initWithStartingColor:rightTopColor endingColor:rightBottomColor];
    [rightGradient drawInRect:rightRect angle:-90];
    [[NSColor whiteColor] setFill];
    NSRectFill(rightHighlightRect);

    // Draw a "faked" shadow to separate the two sides of the footer.
    [[NSColor blackColor] setFill];
    NSRectFill(NSMakeRect(37, 0, 1, 36));

    [super drawRect:dirtyRect];
}

@end
