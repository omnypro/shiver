//
//  InnerShadowView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/24/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "NSColor+Hex.h"

#import "InnerShadowView.h"

@implementation InnerShadowView

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
    // Drawing code here.
    [[NSColor colorWithHex:@"#222222"] setFill];
    NSRectFill(dirtyRect);

    // Delcare our inner shadow.
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor colorWithCalibratedWhite:0 alpha:0.5]];
    [shadow setShadowOffset:NSMakeSize(0, 0)];
    [shadow setShadowBlurRadius:16];

    NSBezierPath *insetPath = [NSBezierPath bezierPathWithRect:dirtyRect];
    NSRect insetRect = NSInsetRect([insetPath bounds], -shadow.shadowBlurRadius, -shadow.shadowBlurRadius);
    insetRect = NSOffsetRect(insetRect, -shadow.shadowOffset.width, -shadow.shadowOffset.height);
    insetRect = NSInsetRect(NSUnionRect(insetRect, [insetPath bounds]), -1, -1);

    NSBezierPath *insetNegativePath = [NSBezierPath bezierPathWithRect:insetRect];
    [insetNegativePath appendBezierPath:insetPath];
    [insetNegativePath setWindingRule:NSEvenOddWindingRule];

    [NSGraphicsContext saveGraphicsState];
    {
        NSShadow* shadowWithOffset = [shadow copy];
        CGFloat xOffset = shadowWithOffset.shadowOffset.width + round(insetRect.size.width);
        CGFloat yOffset = shadowWithOffset.shadowOffset.height;
        shadowWithOffset.shadowOffset = NSMakeSize(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset));
        [shadowWithOffset set];
        [[NSColor grayColor] setFill];
        [insetPath addClip];

        NSAffineTransform *transform = [NSAffineTransform transform];
        [transform translateXBy:-round(insetRect.size.width) yBy:0];
        [[transform transformBezierPath:insetNegativePath] fill];
    }
    [NSGraphicsContext restoreGraphicsState];

    [super drawRect:dirtyRect];
}

@end
