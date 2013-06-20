//
//  StreamListViewCell.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "StreamListViewCell.h"

#import "Channel.h"

@implementation StreamListViewCell

- (id)initWithReusableIdentifier: (NSString*)identifier
{
    if (self = [super initWithReusableIdentifier:identifier]) {
        // Initialization code here.
    }

    return self;
}

- (void)prepareForReuse
{
    [self.streamTitleLabel setStringValue:@""];
    [self.streamUserLabel setStringValue:@""];
    [self.streamViewerCountLabel setStringValue:@""];
}

- (void)drawRect:(NSRect)dirtyRect
{
    //// Color Declarations
    NSColor* topGradientColor = [NSColor colorWithCalibratedRed: 0.902 green: 0.906 blue: 0.91 alpha: 1];
    NSColor* bottomGradientColor = [NSColor colorWithCalibratedRed: 0.827 green: 0.831 blue: 0.835 alpha: 1];

    //// Gradient Declarations
    NSGradient* gradient = [[NSGradient alloc] initWithStartingColor: topGradientColor endingColor: bottomGradientColor];

    //// Shadow Declarations
    NSShadow* innerShadow = [[NSShadow alloc] init];
    [innerShadow setShadowColor: [NSColor whiteColor]];
    [innerShadow setShadowOffset: NSMakeSize(0.1, -1.1)];
    [innerShadow setShadowBlurRadius: 0];

    //// Abstracted Attributes
    NSRect roundedRectangleRect = NSMakeRect(5, 0, 310, 110);
    CGFloat roundedRectangleCornerRadius = 2;


    //// Rounded Rectangle Drawing
    NSBezierPath* roundedRectanglePath = [NSBezierPath bezierPathWithRoundedRect: roundedRectangleRect xRadius: roundedRectangleCornerRadius yRadius: roundedRectangleCornerRadius];
    [gradient drawInBezierPath: roundedRectanglePath angle: -90];

    ////// Rounded Rectangle Inner Shadow
    NSRect roundedRectangleBorderRect = NSInsetRect([roundedRectanglePath bounds], -innerShadow.shadowBlurRadius, -innerShadow.shadowBlurRadius);
    roundedRectangleBorderRect = NSOffsetRect(roundedRectangleBorderRect, -innerShadow.shadowOffset.width, -innerShadow.shadowOffset.height);
    roundedRectangleBorderRect = NSInsetRect(NSUnionRect(roundedRectangleBorderRect, [roundedRectanglePath bounds]), -1, -1);

    NSBezierPath* roundedRectangleNegativePath = [NSBezierPath bezierPathWithRect: roundedRectangleBorderRect];
    [roundedRectangleNegativePath appendBezierPath: roundedRectanglePath];
    [roundedRectangleNegativePath setWindingRule: NSEvenOddWindingRule];

    [NSGraphicsContext saveGraphicsState];
    {
        NSShadow* innerShadowWithOffset = [innerShadow copy];
        CGFloat xOffset = innerShadowWithOffset.shadowOffset.width + round(roundedRectangleBorderRect.size.width);
        CGFloat yOffset = innerShadowWithOffset.shadowOffset.height;
        innerShadowWithOffset.shadowOffset = NSMakeSize(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset));
        [innerShadowWithOffset set];
        [[NSColor grayColor] setFill];
        [roundedRectanglePath addClip];
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy: -round(roundedRectangleBorderRect.size.width) yBy: 0];
        [[transform transformBezierPath: roundedRectangleNegativePath] fill];
    }
    [NSGraphicsContext restoreGraphicsState];
}

- (IBAction)redirectToStream:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:self.stream.channel.url];
}

@end
