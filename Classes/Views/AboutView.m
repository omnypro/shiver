//
//  AboutView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/27/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "NSColor+Hex.h"

#import "AboutView.h"

@implementation AboutView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    // Delcare our colors and main gradient first.
    NSColor *topColor = [NSColor colorWithHex:@"#131414"];
    NSColor *bottomColor = [NSColor colorWithHex:@"2F3030"];
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:bottomColor];

    // Draw the main rectangle that'll contain the custom gradient.
    NSRect rect = NSMakeRect(0, 0, NSWidth(dirtyRect), NSHeight(dirtyRect));
    [gradient drawInRect:rect angle:-90];

    // Draw the two horizontal lines that'll separate the panel's content.
    NSRect topLine = NSMakeRect(10, NSHeight(dirtyRect) - 20, NSWidth(dirtyRect) - 20, 1);
    [[NSColor colorWithHex:@"#303030"] setFill];
    NSRectFill(topLine);

    NSRect bottomLine = NSMakeRect(10, 90, NSWidth(dirtyRect) - 20, 1);
    [[NSColor colorWithHex:@"#4A4A4A"] setFill];
    NSRectFill(bottomLine);
}

@end
