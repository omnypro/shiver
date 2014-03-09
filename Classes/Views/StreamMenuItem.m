//
//  StreamMenuItem.m
//  Shiver
//
//  Created by Bryan Veloso on 3/8/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "StreamMenuItem.h"

@implementation StreamMenuItem

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

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];

    if ([[self enclosingMenuItem] isHighlighted]) {
        [[NSColor selectedMenuItemColor] set];
        NSRectFill(rect);

        [self.name setTextColor:[NSColor selectedMenuItemTextColor]];
        [self.game setTextColor:[NSColor selectedMenuItemTextColor]];
        [self.viewers setTextColor:[NSColor selectedMenuItemTextColor]];
    } else {
        [self.name setTextColor:[NSColor controlTextColor]];
        [self.game setTextColor:[NSColor disabledControlTextColor]];
        [self.viewers setTextColor:[NSColor secondarySelectedControlColor]];
    }
}

- (void)mouseUp:(NSEvent*)event
{
    NSMenuItem *menuItem = [self enclosingMenuItem];
    NSMenu *menu = [menuItem menu];
    
    [menu performActionForItemAtIndex:[menu indexOfItem:menuItem]];
    [menu cancelTracking];
}


@end
