//
//  TitleView.m
//  Shiver
//
//  Created by Bryan Veloso on 2/21/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "HexColor.h"
#import "NSBezierPath-PXRoundedRectangleAdditions.h"

#import "TitleView.h"

@implementation TitleView

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

    // Draw the view's footer rectangle and fill it with a gradient.
    NSColor *titleTopColor = [NSColor colorWithHexString:@"#2A2B2E" alpha:1.0];
    NSColor *titleBottomColor = [NSColor colorWithHexString:@"#161719" alpha:1.0];
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:titleTopColor endingColor:titleBottomColor];
    NSBezierPath *titlePath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(240, 0, self.bounds.size.width - 240, self.bounds.size.height) cornerRadius:3 inCorners:OSTopRightCorner];
    [gradient drawInBezierPath:titlePath angle:-90];

    NSRect titleHighlightRect = NSMakeRect(240, 37, self.bounds.size.width - 242, 1);
    [[NSColor colorWithHexString:@"#4B4C51" alpha:1.0] setFill];
    NSRectFill(titleHighlightRect);

    // Draw the view's right shadow.
    NSBezierPath *shadowPath = [NSBezierPath bezierPathWithRect:NSMakeRect(238, 0, 2, self.bounds.size.height)];
    [[NSColor colorWithCalibratedWhite:0 alpha:0.25] setFill];
    [shadowPath fill];
}

@end
