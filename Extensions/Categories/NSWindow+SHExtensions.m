//
//  NSWindow+SHExtensions.m
//  Shiver
//
//  Created by Bryan Veloso on 7/6/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "NSWindow+SHExtensions.h"

@implementation NSWindow (SHExtensions)

- (IBAction)fadeIn:(id)sender
{
    [self setAlphaValue:0];
    [self makeKeyAndOrderFront:nil];
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.1];
    [[self animator] setAlphaValue:1];
    [NSAnimationContext endGrouping];
}

- (IBAction)fadeOut:(id)sender
{
    [NSAnimationContext beginGrouping];
    __block NSWindow *bself = self;
    [[NSAnimationContext currentContext] setDuration:0.1];
    [[NSAnimationContext currentContext] setCompletionHandler:^{
        [bself orderOut:nil];
        [bself setAlphaValue:1];
    }];
    [[self animator] setAlphaValue:0];
    [NSAnimationContext endGrouping];
}

@end
