//
//  StreamListSectionView.m
//  Shiver
//
//  Created by Bryan Veloso on 2/23/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "HexColor.h"

#import "StreamListSectionView.h"

@implementation StreamListSectionView

+ (StreamListSectionView *)initItem
{
	NSNib *nib = [[NSNib alloc] initWithNibNamed:NSStringFromClass(self) bundle:nil];
	NSArray *objects = nil;
    [nib instantiateWithOwner:nil topLevelObjects:&objects];
	for (id object in objects) {
		if ([object isKindOfClass:[JAListViewItem class]]) {
            return object;
        }
    }
	return nil;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self == nil) { return nil; }

    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];

    [self.title setTextColor:[NSColor colorWithHexString:@"#FFFFFF"]];
	
    // Drawing code here.
}

@end
