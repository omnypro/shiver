//
//  StreamImageView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/12/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "StreamImageView.h"

CGFloat const StreamImageViewCornerRadius = 3.0;
CGFloat const StreamImageViewImageInset = 3.0;

@implementation StreamImageView

- (void)drawRect:(NSRect)dirtyRect
{
	[NSGraphicsContext saveGraphicsState];

	NSRect drawingBounds = NSMakeRect(NSMinX(self.bounds), floor(NSMinY(self.bounds) + 1.0), NSWidth(self.bounds), floor(NSHeight(self.bounds) - 1.0));
	NSBezierPath *outerClip = [NSBezierPath bezierPathWithRoundedRect:drawingBounds xRadius:StreamImageViewCornerRadius yRadius:StreamImageViewCornerRadius];
	static NSGradient *backingGrad = nil;
	if (backingGrad == nil) {
		NSColor *startColor = [NSColor colorWithCalibratedWhite:(23.0/255.0) alpha:1.0];
		NSColor *endColor = [NSColor colorWithCalibratedWhite:(36.0/255.0) alpha:1.0];
		backingGrad = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
	}
	[backingGrad drawInBezierPath:outerClip angle:90.0];

    [NSGraphicsContext restoreGraphicsState];
}

@end
