//
//  UserImageView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/19/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "UserImageView.h"

#import "User.h"

@implementation UserImageView

- (void)drawRect:(NSRect)dirtyRect
{
    CGFloat cornerRadius = 1.0;
    CGFloat imageInset = 2.0;
    CGFloat highlightCurveStartXOffset = 5.0;
    CGFloat highlightCurveEndYOffset = 5.0;

    [NSGraphicsContext saveGraphicsState];

	NSRect drawingBounds = NSMakeRect(NSMinX(self.bounds), floor(NSMinY(self.bounds) + 1.0), NSWidth(self.bounds), floor(NSHeight(self.bounds) - 1.0));
	NSBezierPath *outerClip = [NSBezierPath bezierPathWithRoundedRect:drawingBounds xRadius:cornerRadius yRadius:cornerRadius];
	static NSGradient *backingGrad = nil;
	if (backingGrad == nil) {
		NSColor *startColor = [NSColor colorWithCalibratedWhite:(23.0/255.0) alpha:1.0];
		NSColor *endColor = [NSColor colorWithCalibratedWhite:(36.0/255.0) alpha:1.0];
		backingGrad = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
	}
	[backingGrad drawInBezierPath:outerClip angle:90.0];

	CGFloat y = NSMinY(self.bounds) + 0.5;
	[[NSColor colorWithCalibratedWhite:1.0 alpha:0.5] set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(self.bounds) + cornerRadius, y) toPoint:NSMakePoint(NSMaxX(self.bounds) - cornerRadius, y)];

	NSRect imageRect = NSInsetRect(drawingBounds, imageInset, imageInset);
	[self.image drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];

	NSBezierPath *highlightPath = [NSBezierPath bezierPath];
	[highlightPath moveToPoint:NSMakePoint(floor(NSMinX(imageRect) + highlightCurveStartXOffset), NSMinY(imageRect))];
	NSPoint controlPoint = NSMakePoint(NSMidX(imageRect), NSMidY(imageRect));
	[highlightPath curveToPoint:NSMakePoint(NSMaxX(imageRect), floor(NSMaxY(imageRect) - highlightCurveEndYOffset)) controlPoint1:controlPoint controlPoint2:controlPoint];

	[highlightPath lineToPoint:NSMakePoint(NSMaxX(imageRect), NSMaxY(imageRect))];
	[highlightPath lineToPoint:NSMakePoint(NSMinX(imageRect), NSMaxY(imageRect))];
	[highlightPath lineToPoint:NSMakePoint(NSMinX(imageRect), NSMinY(imageRect))];
	[highlightPath closePath];

	static NSGradient *highlightGrad = nil;
	if (highlightGrad == nil) {
		NSColor *startColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.2];
		NSColor *endColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.0];
		highlightGrad = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
	}

	[highlightGrad drawInBezierPath:highlightPath angle:270.0];

	[NSGraphicsContext restoreGraphicsState];
}

- (void)mouseDown:(NSEvent *)theEvent
{

}

@end
