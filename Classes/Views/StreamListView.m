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

    // Draw the view's footer rectangle and fill it with a gradient.
    NSColor *footerTopColor = [NSColor colorWithHexString:@"#242428" alpha:1.0];
    NSColor *footerBottomColor = [NSColor colorWithHexString:@"#1C1D20" alpha:1.0];
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:footerTopColor endingColor:footerBottomColor];
    NSBezierPath *footerPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, self.bounds.size.width, 43)];
    [gradient drawInBezierPath:footerPath angle:-90];

    // Draw the view's footer's top border rectangle.
    NSRect borderRect = NSMakeRect(0, 43, self.bounds.size.width, 3);
    [[NSColor colorWithHexString:@"#452D89" alpha:1.0] setFill];
    NSRectFill(borderRect);

    NSRect borderHighlightRect = NSMakeRect(0, 45, self.bounds.size.width, 1);
    [[NSColor colorWithHexString:@"#5C3DAF" alpha:1.0] setFill];
    NSRectFill(borderHighlightRect);

    NSRect borderShadowRect = NSMakeRect(0, 42, self.bounds.size.width, 1);
    [[NSColor colorWithHexString:@"#151518" alpha:1.0] setFill];
    NSRectFill(borderShadowRect);

    // Draw the view's right shadow.
    NSBezierPath *shadowPath = [NSBezierPath bezierPathWithRect:NSMakeRect(self.bounds.size.width - 2, 0, 2, self.bounds.size.height)];
    [[NSColor colorWithCalibratedWhite:0 alpha:0.25] setFill];
    [shadowPath fill];
}

@end
