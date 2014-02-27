//
//  StreamListView.m
//  Shiver
//
//  Created by Bryan Veloso on 2/21/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "HexColor.h"

#import "StreamListView.h"

@implementation StreamListView

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

    // Draw the initial background rectangle and fill it.
    NSRect initialRect = NSInsetRect([self bounds], 0.0, 0.0);
    [[NSColor colorWithHexString:@"#121212" alpha:1.0] setFill];
    NSRectFill(initialRect);

    // Draw the view's footer's top border rectangle.
    NSRect borderHighlightRect = NSMakeRect(0, 42, self.bounds.size.width, 1);
    [[NSColor colorWithHexString:@"#141414" alpha:1.0] setFill];
    NSRectFill(borderHighlightRect);

    NSRect borderShadowRect = NSMakeRect(0, 43, self.bounds.size.width, 1);
    [[NSColor colorWithHexString:@"#0C0C0C" alpha:1.0] setFill];
    NSRectFill(borderShadowRect);

    // Draw the view's right shadow.
    NSBezierPath *shadowPath = [NSBezierPath bezierPathWithRect:NSMakeRect(self.bounds.size.width - 2, 0, 2, self.bounds.size.height)];
    [[NSColor colorWithCalibratedWhite:0 alpha:0.25] setFill];
    [shadowPath fill];
}

@end
