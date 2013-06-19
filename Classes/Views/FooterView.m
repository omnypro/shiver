//
//  FooterView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/12/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "FooterView.h"

#import "NSColor+Hex.h"

@implementation FooterView

- (void)drawRect:(NSRect)dirtyRect
{
    // Declare our colors and gradients first. There's a lot of them.
    NSColor *leftTopColor = [NSColor colorWithHex:@"#343434"];;
    NSColor *leftBottomColor = [NSColor colorWithHex:@"#141414"];
    NSColor *rightTopColor = [NSColor colorWithHex:@"#EEEEEF"];
    NSColor *rightBottomColor = [NSColor colorWithHex:@"#C8C8CE"];
    NSColor *leftInnerShadowColor = [NSColor colorWithHex:@"#555555"];
    NSGradient *leftGradient = [[NSGradient alloc] initWithStartingColor:leftTopColor endingColor:leftBottomColor];
    NSGradient *rightGradient = [[NSGradient alloc] initWithStartingColor:rightTopColor endingColor:rightBottomColor];

    // Declare our inner shadows.
    NSShadow* leftHighlight = [[NSShadow alloc] init];
    [leftHighlight setShadowColor:leftInnerShadowColor];
    [leftHighlight setShadowOffset:NSMakeSize(0, -1)];
    [leftHighlight setShadowBlurRadius:0];
    NSShadow* rightHighlight = [[NSShadow alloc] init];
    [rightHighlight setShadowColor:[NSColor whiteColor]];
    [rightHighlight setShadowOffset:NSMakeSize(0, -1)];
    [rightHighlight setShadowBlurRadius:0];

    // Draw the left side of the two-tone footer first, then apply our
    // previously declared inner shadow.
    NSBezierPath* leftPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, 38, 36)];
    [leftGradient drawInBezierPath:leftPath angle:-90];

    NSRect leftRect = NSInsetRect([leftPath bounds], -leftHighlight.shadowBlurRadius, -leftHighlight.shadowBlurRadius);
    leftRect = NSOffsetRect(leftRect, -leftHighlight.shadowOffset.width, -leftHighlight.shadowOffset.height);
    leftRect = NSInsetRect(NSUnionRect(leftRect, [leftPath bounds]), -1, -1);

    NSBezierPath* leftNegativePath = [NSBezierPath bezierPathWithRect:leftRect];
    [leftNegativePath appendBezierPath:leftPath];
    [leftNegativePath setWindingRule:NSEvenOddWindingRule];

    [NSGraphicsContext saveGraphicsState];
    {
        NSShadow* leftHighlightWithOffset = [leftHighlight copy];
        CGFloat xOffset = leftHighlightWithOffset.shadowOffset.width + round(leftRect.size.width);
        CGFloat yOffset = leftHighlightWithOffset.shadowOffset.height;
        leftHighlightWithOffset.shadowOffset = NSMakeSize(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset));
        [leftHighlightWithOffset set];
        [[NSColor grayColor] setFill];
        [leftPath addClip];
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy:-round(leftRect.size.width) yBy: 0];
        [[transform transformBezierPath:leftNegativePath] fill];
    }
    [NSGraphicsContext restoreGraphicsState];

    // Draw the right side of the two-tone footer, then apply our previously
    // declared inner shadow.
    NSBezierPath* rightPath = [NSBezierPath bezierPathWithRect: NSMakeRect(38, 0, 282, 36)];
    [rightGradient drawInBezierPath: rightPath angle: -90];

    NSRect rightRect = NSInsetRect([rightPath bounds], -rightHighlight.shadowBlurRadius, -rightHighlight.shadowBlurRadius);
    rightRect = NSOffsetRect(rightRect, -rightHighlight.shadowOffset.width, -rightHighlight.shadowOffset.height);
    rightRect = NSInsetRect(NSUnionRect(rightRect, [rightPath bounds]), -1, -1);

    NSBezierPath* rightNegativePath = [NSBezierPath bezierPathWithRect:rightRect];
    [rightNegativePath appendBezierPath:rightPath];
    [rightNegativePath setWindingRule:NSEvenOddWindingRule];

    [NSGraphicsContext saveGraphicsState];
    {
        NSShadow* rightHighlightWithOffset = [rightHighlight copy];
        CGFloat xOffset = rightHighlightWithOffset.shadowOffset.width + round(rightRect.size.width);
        CGFloat yOffset = rightHighlightWithOffset.shadowOffset.height;
        rightHighlightWithOffset.shadowOffset = NSMakeSize(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset));
        [rightHighlightWithOffset set];
        [[NSColor grayColor] setFill];
        [rightPath addClip];
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy:-round(rightRect.size.width) yBy: 0];
        [[transform transformBezierPath:rightNegativePath] fill];
    }
    [NSGraphicsContext restoreGraphicsState];

    // Draw a "faked" shadow to separate the two sides of the footer.
    NSBezierPath* rectanglePath = [NSBezierPath bezierPathWithRect:NSMakeRect(37, 0, 1, 36)];
    [[NSColor blackColor] setFill];
    [rectanglePath fill];
}

@end
