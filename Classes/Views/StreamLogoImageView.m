//
//  StreamLogoImageView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/12/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "StreamLogoImageView.h"

CGFloat const ImageViewCornerRadius = 2.0;
CGFloat const ImageViewImageInset = 0.0;

@implementation StreamLogoImageView

- (void)drawRect:(NSRect)dirtyRect
{
    [NSGraphicsContext saveGraphicsState];

    NSRect drawingBounds = NSInsetRect(self.bounds, 0.0, 0.0);
    NSBezierPath *logoPath = [NSBezierPath bezierPathWithRoundedRect:drawingBounds xRadius:ImageViewCornerRadius yRadius:ImageViewCornerRadius];
    [logoPath addClip];

    NSRect imageRect = NSInsetRect(drawingBounds, ImageViewImageInset, ImageViewImageInset);
    [self.image drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];

    [NSGraphicsContext restoreGraphicsState];
}

@end
