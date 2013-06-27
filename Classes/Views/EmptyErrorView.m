//
//  EmptyErrorView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/24/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "EmptyErrorView.h"

@interface EmptyErrorView ()
@property (weak) IBOutlet NSImageView *imageView;
@property (weak) IBOutlet NSTextField *titleLabel;
@property (weak) IBOutlet NSTextField *subTitleLabel;
@end

@implementation EmptyErrorView

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

- (NSView *)emptyViewWithTitle:(NSString *)title subTitle:(NSString *)subTitle
{
    [self.imageView setImage:[NSImage imageNamed:@"EmptyStreamList"]];
    [self.titleLabel setStringValue:title];
    [self.subTitleLabel setStringValue:[NSString stringWithFormat:@"(%@)", subTitle]];
    return self;
}

- (NSView *)errorViewWithTitle:(NSString *)title subTitle:(NSString *)subTitle
{
    [self.imageView setImage:[NSImage imageNamed:@"Error"]];
    [self.titleLabel setStringValue:title];
    [self.subTitleLabel setStringValue:[NSString stringWithFormat:@"(%@)", subTitle]];
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
}

@end
