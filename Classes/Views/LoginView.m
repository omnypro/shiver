//
//  LoginView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/11/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "LoginView.h"

@implementation LoginView

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
    NSColor* twitchColor = [NSColor colorWithCalibratedRed: 0.392 green: 0.255 blue: 0.647 alpha: 1];
    NSBezierPath* sidebarPath = [NSBezierPath bezierPathWithRect: NSMakeRect(0, 180, 480, 60)];
    [twitchColor setFill];
    [sidebarPath fill];
}

@end
