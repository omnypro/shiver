//
//  StreamListViewItem.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "StreamListViewItem.h"

#import "Channel.h"

@implementation StreamListViewItem

+ (StreamListViewItem *)initItem
{
    static NSNib *nib = nil;
    if(nib == nil) {
        nib = [[NSNib alloc] initWithNibNamed:NSStringFromClass(self) bundle:nil];
    }

    NSArray *objects = nil;
    [nib instantiateWithOwner:nil topLevelObjects:&objects];
    for(id object in objects) {
        if ([object isKindOfClass:self]) {
            return object;
        }
    }

    NSAssert1(NO, @"No view of class %@ found.", NSStringFromClass(self));
    return nil;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Abstracted attributes.
    CGFloat cornerRadius = 2;
    NSRect frame = dirtyRect;

    // Declare our colors first.
    NSColor *topColor = [NSColor colorWithCalibratedRed:0.902 green:0.906 blue:0.91 alpha:1];
    NSColor *bottomColor = [NSColor colorWithCalibratedRed:0.827 green:0.831 blue:0.835 alpha:1];

    // Next, declare the necessary gradient and shadow.
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:bottomColor];
    NSShadow *innerShadow = [[NSShadow alloc] init];
    [innerShadow setShadowColor:[NSColor whiteColor]];
    [innerShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
    [innerShadow setShadowBlurRadius:0];

    // Draw the box.
    NSRect rect = NSMakeRect(5, 0, NSWidth(frame) - 10, 110);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:cornerRadius yRadius:cornerRadius];
    [gradient drawInBezierPath:path angle:-90];

    NSRect borderRect = NSInsetRect([path bounds], -innerShadow.shadowBlurRadius, -innerShadow.shadowBlurRadius);
    borderRect = NSOffsetRect(borderRect, -innerShadow.shadowOffset.width, -innerShadow.shadowOffset.height);
    borderRect = NSInsetRect(NSUnionRect(borderRect, [path bounds]), -1, -1);

    NSBezierPath *negativePath = [NSBezierPath bezierPathWithRect:borderRect];
    [negativePath appendBezierPath:path];
    [negativePath setWindingRule:NSEvenOddWindingRule];

    [NSGraphicsContext saveGraphicsState];
    {
        NSShadow *shadowWithOffset = [innerShadow copy];
        CGFloat xOffset = shadowWithOffset.shadowOffset.width + round(borderRect.size.width);
        CGFloat yOffset = shadowWithOffset.shadowOffset.height;
        shadowWithOffset.shadowOffset = NSMakeSize(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset));
        [shadowWithOffset set];
        [[NSColor grayColor] setFill];
        [path addClip];
        NSAffineTransform *transform = [NSAffineTransform transform];
        [transform translateXBy:-round(borderRect.size.width) yBy: 0];
        [[transform transformBezierPath:negativePath] fill];
    }
    [NSGraphicsContext restoreGraphicsState];
}

- (IBAction)redirectToStream:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:self.stream.channel.url];
}

@end
