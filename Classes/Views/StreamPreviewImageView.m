//
//  StreamPreviewImageView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/18/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "NSColor+Hex.h"
#import "NSImage+MGCropExtensions.h"

#import "StreamPreviewImageView.h"

@implementation StreamPreviewImageView

- (void)drawRect:(NSRect)dirtyRect
{
    // Draw the inner rectangle and fill it with black.
    NSRect initialRect = NSMakeRect(0, 0, NSWidth(dirtyRect), 100);
    [[NSColor colorWithHex:@"#000"] setFill];
    NSRectFill(initialRect);

    // Crop the preview image, because squishy images suck.
    NSImage *croppedImage = [self.image imageToFitSize:NSMakeSize(NSWidth(dirtyRect), 100) method:MGImageResizeCrop];
    [croppedImage drawInRect:initialRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.9];

    // Draw a highlight box on the image to help with the separation between
    // stream items.
    NSRect imageHighlightRect = NSMakeRect(0, 99, NSWidth(dirtyRect), 1);
    [[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0.15] setFill];
    [NSBezierPath fillRect:imageHighlightRect];

    // Draw the title rectangle and a gradiented clear-to-black black
    // background for the title text to sit on.
    NSColor *titleBackgroundColor = [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.7];
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor clearColor] endingColor:titleBackgroundColor];
    NSRect titleRect = NSMakeRect(0, 20, NSWidth(dirtyRect), 70);
    [gradient drawInRect:titleRect angle:-90];

    // Finally, work on the metadata footer that houses the bottom half of the
    // avatar, the streamer's username and the game they're playing.
    //
    // Declare the necessary gradient and draw it into the box. Then draw and
    // fill the cooresponding box for the highlight too.
    NSColor *metadataTopColor = [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.85];
    NSColor *metadataBottomColor = [NSColor colorWithCalibratedRed:0.06 green:0.06 blue:0.06 alpha:0.90];
    NSGradient *metadataGradient = [[NSGradient alloc] initWithStartingColor:metadataTopColor endingColor:metadataBottomColor];
    NSRect metadataRect = NSMakeRect(0, 0, NSWidth(dirtyRect), 20);
    [metadataGradient drawInRect:metadataRect angle:-90];
    NSRect highlightRect = NSMakeRect(0, 20, NSWidth(dirtyRect), 1);
    [[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0.10] setFill];
    [NSBezierPath fillRect:highlightRect];
}

- (BOOL)isOpaque
{
    return YES;
}

@end
