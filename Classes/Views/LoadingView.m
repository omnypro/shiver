//
//  LoadingView.m
//  Shiver
//
//  Created by Bryan Veloso on 7/2/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "LoadingView.h"

@implementation LoadingView

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    [[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.75] setFill];
    [NSBezierPath fillRect:[self bounds]];
}

- (BOOL)isOpaque
{
    return NO;
}

@end
