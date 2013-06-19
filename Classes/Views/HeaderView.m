//
//  HeaderView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/19/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "HeaderView.h"

#import "NSColor+Hex.h"

@implementation HeaderView

- (void)drawRect:(NSRect)dirtyRect
{
    //// Color Declarations
    NSColor* headerLeftTopColor = [NSColor colorWithHex:@"#545353"];
    NSColor* headerLeftBottomColor = [NSColor colorWithHex:@"#2A2A2A"];
    NSColor* headerLeftInnerShadowColor = [NSColor colorWithHex:@"#838282"];

    //// Gradient Declarations
    NSGradient* footerLeftGradient = [[NSGradient alloc] initWithStartingColor: headerLeftTopColor endingColor: headerLeftBottomColor];

    //// Shadow Declarations
    NSShadow* footerLeftInnerShadow = [[NSShadow alloc] init];
    [footerLeftInnerShadow setShadowColor: headerLeftInnerShadowColor];
    [footerLeftInnerShadow setShadowOffset: NSMakeSize(0.0, -0.51)];
    [footerLeftInnerShadow setShadowBlurRadius: 0];

    //// Abstracted Attributes
    NSRect footerLeftRect = NSMakeRect(0, 0, 38, 34);
    CGFloat footerLeftCornerRadius = 5;


    //// Footer (Left) Drawing
    NSRect footerLeftInnerRect = NSInsetRect(footerLeftRect, footerLeftCornerRadius, footerLeftCornerRadius);
    NSBezierPath* footerLeftPath = [NSBezierPath bezierPath];
    [footerLeftPath moveToPoint: NSMakePoint(NSMinX(footerLeftRect), NSMinY(footerLeftRect))];
    [footerLeftPath lineToPoint: NSMakePoint(NSMaxX(footerLeftRect), NSMinY(footerLeftRect))];
    [footerLeftPath lineToPoint: NSMakePoint(NSMaxX(footerLeftRect), NSMaxY(footerLeftRect))];
    [footerLeftPath appendBezierPathWithArcWithCenter: NSMakePoint(NSMinX(footerLeftInnerRect), NSMaxY(footerLeftInnerRect)) radius: footerLeftCornerRadius startAngle: 90 endAngle: 180];
    [footerLeftPath closePath];
    [footerLeftGradient drawInBezierPath: footerLeftPath angle: -90];

    ////// Footer (Left) Inner Shadow
    NSRect footerLeftBorderRect = NSInsetRect([footerLeftPath bounds], -footerLeftInnerShadow.shadowBlurRadius, -footerLeftInnerShadow.shadowBlurRadius);
    footerLeftBorderRect = NSOffsetRect(footerLeftBorderRect, -footerLeftInnerShadow.shadowOffset.width, -footerLeftInnerShadow.shadowOffset.height);
    footerLeftBorderRect = NSInsetRect(NSUnionRect(footerLeftBorderRect, [footerLeftPath bounds]), -1, -1);

    NSBezierPath* footerLeftNegativePath = [NSBezierPath bezierPathWithRect: footerLeftBorderRect];
    [footerLeftNegativePath appendBezierPath: footerLeftPath];
    [footerLeftNegativePath setWindingRule: NSEvenOddWindingRule];

    [NSGraphicsContext saveGraphicsState];
    {
        NSShadow* footerLeftInnerShadowWithOffset = [footerLeftInnerShadow copy];
        CGFloat xOffset = footerLeftInnerShadowWithOffset.shadowOffset.width + round(footerLeftBorderRect.size.width);
        CGFloat yOffset = footerLeftInnerShadowWithOffset.shadowOffset.height;
        footerLeftInnerShadowWithOffset.shadowOffset = NSMakeSize(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset));
        [footerLeftInnerShadowWithOffset set];
        [[NSColor grayColor] setFill];
        [footerLeftPath addClip];
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy: -round(footerLeftBorderRect.size.width) yBy: 0];
        [[transform transformBezierPath: footerLeftNegativePath] fill];
    }
    [NSGraphicsContext restoreGraphicsState];
    
    
    
    //// Rectangle Drawing
    NSBezierPath* rectanglePath = [NSBezierPath bezierPathWithRect: NSMakeRect(37, 0, 1, 33.5)];
    [[NSColor colorWithHex:@"#333333"] setFill];
    [rectanglePath fill];
    
    
}

@end
