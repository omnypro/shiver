//
//  StreamPreviewImageView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/18/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "StreamPreviewImageView.h"

#import "NSImage+MGCropExtensions.h"

@implementation StreamPreviewImageView

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
    // Abstracted attributes.
    NSRect initialRect = NSMakeRect(0, 0, 304, 85);
    CGFloat cornerRadius = 2;

    // Draw the inner rectangle with the bottom rounded corners.
    NSRect innerRect = NSInsetRect(initialRect, cornerRadius, cornerRadius);
    NSBezierPath* path = [NSBezierPath bezierPath];
    [path appendBezierPathWithArcWithCenter: NSMakePoint(NSMinX(innerRect), NSMinY(innerRect)) radius: cornerRadius startAngle: 180 endAngle: 270];
    [path appendBezierPathWithArcWithCenter: NSMakePoint(NSMaxX(innerRect), NSMinY(innerRect)) radius: cornerRadius startAngle: 270 endAngle: 360];
    [path lineToPoint: NSMakePoint(NSMaxX(initialRect), NSMaxY(initialRect))];
    [path lineToPoint: NSMakePoint(NSMinX(initialRect), NSMaxY(initialRect))];
    [path closePath];
    [[NSColor blackColor] setFill];
    [path fill];

    // Crop the preview image, because squishy images suck.
    NSImage *croppedImage;
    MGImageResizingMethod method = MGImageResizeCropStart;
    NSSize targetSize = NSMakeSize(304, 85);
    croppedImage = [self.image imageToFitSize:targetSize method:method];
    [croppedImage drawInRect:innerRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

@end
