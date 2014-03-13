//
//  VolumeSliderCell.m
//  Shiver
//
//  Created by Bryan Veloso on 3/12/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "HexColor.h"

#import "VolumeSliderCell.h"

@implementation VolumeSliderCell

- (void)drawKnob:(NSRect)knobRect
{
    [super drawKnob:knobRect];
}

- (void)drawBarInside:(NSRect)rect flipped:(BOOL)flipped
{
    NSRect knobRect = [self knobRectFlipped:flipped];

    rect.origin.y -= 1;
    rect.size.height += 1;

    [NSGraphicsContext restoreGraphicsState];

    NSRect shadowRect = NSMakeRect(rect.origin.x, rect.origin.y + 1, rect.size.width, rect.size.height);
    NSBezierPath *barShadow = [NSBezierPath bezierPathWithRoundedRect:shadowRect xRadius:rect.size.height / 2 yRadius:rect.size.height / 2];
    [[NSColor colorWithHexString:@"#52565B"] setFill];
    [barShadow fill];

    NSBezierPath *bar = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:rect.size.height / 2 yRadius:rect.size.height / 2];
    [[NSColor colorWithHexString:@"#111315"] setFill];
    [bar fill];

    NSRect leftRect = rect;
    leftRect.origin.x = 3;
    leftRect.origin.y = 6;
    leftRect.size.width = knobRect.origin.x + (knobRect.size.width / 2);
    leftRect.size.height = rect.size.height - 2;
    NSBezierPath *leftPath = [NSBezierPath bezierPathWithRoundedRect:leftRect xRadius:leftRect.size.height / 2 yRadius:leftRect.size.height / 2];
    NSGradient *leftGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithHexString:@"#2D5ED8"] endingColor:[NSColor colorWithHexString:@"#183CBC"]];
    [leftGradient drawInBezierPath:leftPath angle:-90];

    [NSGraphicsContext saveGraphicsState];
}

- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView
{
	// Make sure the view is cleared properly when drawn.
	[controlView setNeedsDisplay:YES];
	return [super continueTracking:lastPoint at:currentPoint inView:controlView];
}

@end
