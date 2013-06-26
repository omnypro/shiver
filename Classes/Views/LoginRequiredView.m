//
//  LoginRequiredView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/26/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "LoginRequiredView.h"

@interface LoginRequiredView ()
- (IBAction)login:(id)sender;
@end

@implementation LoginRequiredView

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

- (IBAction)login:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:RequestToOpenPreferencesNotification object:self userInfo:nil];
}

@end
