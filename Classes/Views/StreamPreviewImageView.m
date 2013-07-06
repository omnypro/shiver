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
    // Draw the inner rectangle.
    NSRect initialRect = NSMakeRect(0, 0, NSWidth(dirtyRect), 80);
    [[NSColor colorWithHex:@"#222222"] setFill];
    NSRectFill(initialRect);

    // Crop the preview image, because squishy images suck.
    NSImage *croppedImage = [self.image imageToFitSize:NSMakeSize(NSWidth(dirtyRect), 80) method:MGImageResizeCrop];
    [croppedImage drawInRect:initialRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.8];

    // Draw the title rectangle and a gradiented clear-to-black black
    // background for the title text to sit on.
    NSColor *titleBackgroundColor = [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.9];
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor clearColor] endingColor:titleBackgroundColor];
    NSRect titleRect = NSMakeRect(0, 0, NSWidth(dirtyRect), 80);
    [gradient drawInRect:titleRect angle:-90];
}

- (BOOL)isOpaque
{
    return YES;
}

@end
