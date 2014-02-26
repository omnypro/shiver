//
//  EmptyViewerView.m
//  Shiver
//
//  Created by Bryan Veloso on 2/25/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "HexColor.h"
#import "NSBezierPath-PXRoundedRectangleAdditions.h"

#import "EmptyViewerView.h"

@implementation EmptyViewerView

+ (id)init
{
    NSNib *nib = [[NSNib alloc] initWithNibNamed:@"EmptyViewer" bundle:nil];
	NSArray *objects = nil;
    [nib instantiateWithOwner:nil topLevelObjects:&objects];
	for (id object in objects)
		if ([object isKindOfClass:[NSView class]]) {
            return object;
        }
	return nil;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];

    // Draw the view's background.
    NSColor *backgroundTop = [NSColor colorWithHexString:@"#242428"];
    NSColor *backgroundBottom = [NSColor colorWithHexString:@"#151619"];
    NSGradient *backgroundGradient = [[NSGradient alloc] initWithStartingColor:backgroundTop endingColor:backgroundBottom];
    NSBezierPath *backgroundPath = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect([self bounds], 0.0, 0.0) cornerRadius:2.0 inCorners:OSBottomRightCorner];
    [backgroundGradient drawInBezierPath:backgroundPath angle:-90];

    // Draw the overlaying rectangle.
    NSColor *overlayShadow = [NSColor colorWithHexString:@"#242428"];
    NSBezierPath *overlayShadowPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(5, 5, self.bounds.size.width - 10, self.bounds.size.height) cornerRadius:2.0 inCorners:OSBottomRightCorner];
    [overlayShadow set];
    [overlayShadowPath fill];

    NSColor *overlay = [NSColor colorWithHexString:@"#101113"];
    NSBezierPath *overlayPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(5, 6, self.bounds.size.width - 10, self.bounds.size.height) cornerRadius:2.0 inCorners:OSBottomRightCorner];
    [overlay set];
    [overlayPath fill];
}

@end
