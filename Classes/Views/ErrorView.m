//
//  EmptyErrorView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/24/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "HexColor.h"

#import "ErrorView.h"

@implementation ErrorView

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    [self.titleLabel setTextColor:[NSColor colorWithHexString:@"#FFFFFF"]];

    [[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.75] setFill];
    [NSBezierPath fillRect:[self bounds]];
}

- (BOOL)isOpaque
{
    return NO;
}

@end
