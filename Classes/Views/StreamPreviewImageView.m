//
//  StreamPreviewImageView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/18/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "StreamPreviewImageView.h"

#import "NSColor+Hex.h"
#import "NSImage+MGCropExtensions.h"

@implementation StreamPreviewImageView

- (void)drawRect:(NSRect)dirtyRect
{
    // Draw the inner rectangle with the bottom rounded corners.
    NSRect initialRect = NSMakeRect(0, 0, NSWidth(dirtyRect), 90);
    [[NSColor colorWithHex:@"#222222"] setFill];
    NSRectFill(initialRect);

    // Crop the preview image, because squishy images suck.
    NSImage *croppedImage = [self.image imageToFitSize:NSMakeSize(NSWidth(dirtyRect), 90) method:MGImageResizeCropStart];
    [croppedImage drawInRect:initialRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.8];

    // Draw the title rectangle with the same bottom rounded corners and a
    // translucent black background for the title text to sit on.
    NSColor *titleBackgroundColor = [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.8];
    NSRect titleRect = NSMakeRect(0, 0, NSWidth(dirtyRect), 50);
    [titleBackgroundColor setFill];
    [NSBezierPath fillRect:titleRect];
}

- (BOOL)isOpaque
{
    return YES;
}

@end
