//
//  StreamListEmptyItemView.m
//  Shiver
//
//  Created by Bryan Veloso on 3/5/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "HexColor.h"
#import "NSBezierPath-PXRoundedRectangleAdditions.h"

#import "StreamListEmptyItemView.h"

@implementation StreamListEmptyItemView

+ (StreamListEmptyItemView *)initItem
{
	NSNib *nib = [[NSNib alloc] initWithNibNamed:NSStringFromClass(self) bundle:nil];
	NSArray *objects = nil;
    [nib instantiateWithOwner:self topLevelObjects:&objects];
	for (id object in objects) {
		if ([object isKindOfClass:[JAListViewItem class]]) {
            return object;
        }
    }
	return nil;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];

    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(10.5, 5.5, 220, 50) xRadius:3.0 yRadius:3.0];
    [path setLineWidth:1.0];
    [[NSColor colorWithHexString:@"#202020"] setStroke];
    [path stroke];

    [self.emptyLabel setTextColor:[NSColor colorWithHexString:@"#303030"]];
}

@end
