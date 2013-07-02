//
//  LoadingView.m
//  Shiver
//
//  Created by Bryan Veloso on 7/2/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "YRKSpinningProgressIndicator.h"

#import "LoadingView.h"

@interface LoadingView () {
    IBOutlet YRKSpinningProgressIndicator *_progressIndicator;
}

@end

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

- (NSView *)loadingViewWithProgressIndicator
{
    [_progressIndicator setColor:[NSColor whiteColor]];
    [_progressIndicator setBackgroundColor:[NSColor clearColor]];
    [_progressIndicator setUsesThreadedAnimation:YES];
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    NSRect rect = dirtyRect;
    [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.8];
    [NSBezierPath fillRect:rect];
}

@end