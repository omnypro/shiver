//
//  LoadingView.m
//  Shiver
//
//  Created by Bryan Veloso on 7/2/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "LoadingView.h"

@implementation LoadingView

+ (id)init
{
    NSNib *nib = [[NSNib alloc] initWithNibNamed:NSStringFromClass(self) bundle:nil];
	NSArray *objects = nil;
    [nib instantiateWithOwner:nil topLevelObjects:&objects];
	for (id object in objects)
		if ([object isKindOfClass:[NSView class]]) {
            return object;
        }
	return nil;
}

- (LoadingView *)loadingViewWithProgressIndicator
{
    [_progressIndicator setColor:[NSColor whiteColor]];
    [_progressIndicator setBackgroundColor:[NSColor clearColor]];
    [_progressIndicator setUsesThreadedAnimation:NO];
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    NSRect rect = dirtyRect;
    [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.5];
    [NSBezierPath fillRect:rect];
}

- (BOOL)isOpaque
{
    return YES;
}

@end
