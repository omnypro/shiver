//
//  HeaderView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/19/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "HexColor.h"

#import "HeaderView.h"

@implementation HeaderView

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    // Declare our colors first.
    NSColor *topColor = [NSColor colorWithHexString:@"#F4F4F5" alpha:1];
    NSColor *bottomColor = [NSColor colorWithHexString:@"#C4C4C5" alpha:1];
    NSColor *highlightColor = [NSColor colorWithHexString:@"#FFFFFF" alpha:1];
    NSColor *shadowColor = [NSColor colorWithHexString:@"#9A9B9F" alpha:1];

    // We're only drawing the left side of the two-tone header.
    NSRect rect = NSMakeRect(0, 0, 320, 32);
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:bottomColor];
    [gradient drawInRect:rect angle:-90];

    // Draw boxes for the highlight and shadow too.
    NSRect shadowRect = NSMakeRect(0, 0, 320, 1);
    [shadowColor setFill];
    NSRectFill(shadowRect);

    NSRect highlightRect = NSMakeRect(0, 31, 320, 1);
    [highlightColor setFill];
    NSRectFill(highlightRect);
}

- (BOOL)isOpaque
{
    return YES;
}

@end
