//
//  NSView+Animations.m
//  Shiver
//
//  Created by Bryan Veloso on 7/3/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "NSView+Animations.h"

@implementation NSView (Animations)

- (void)addSubview:(NSView *)aView animated:(BOOL)animated
{
    [aView setAlphaValue:0.f];
    [aView setFrameOrigin:NSZeroPoint];

    CGFloat duration = animated ? (([[[self window] currentEvent] modifierFlags] & NSShiftKeyMask) ? 1.f : 0.25f ) : 0.f;
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:duration];

    [self addSubview:aView];
    [[aView animator] setAlphaValue:1.f];

    [NSAnimationContext endGrouping];
}

- (void)removeFromSuperviewAnimated:(BOOL)animated
{
    CGFloat duration = animated ? (([[[self window] currentEvent] modifierFlags] & NSShiftKeyMask) ? 1.f : 0.25f ) : 0.f;

//    [[NSAnimationContext currentContext] setCompletionHandler:^{
//        [self removeFromSuperview];
//    }];

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:duration];

    [[self animator] setAlphaValue:0.f];

    [NSAnimationContext endGrouping];

    // if we were Lion-only, using built-in completion handler would be a better idea
    [self performSelector:@selector(removeFromSuperview)
               withObject:nil
               afterDelay:duration];
}

@end
