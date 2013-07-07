//
//  FooterView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/12/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "FooterView.h"

#import "HexColor.h"

@implementation FooterView

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    // Declare our colors first. There's a lot of them.
    NSColor *topColor = [NSColor colorWithHexString:@"#2f2f2f" alpha:1];;
    NSColor *bottomColor = [NSColor colorWithHexString:@"#141414" alpha:1];
    NSColor *highlightColor = [NSColor colorWithHexString:@"#3F3F40" alpha:1];

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
