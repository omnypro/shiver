//
//  NSView+SHExtensions.m
//  Shiver
//
//  Created by Bryan Veloso on 6/25/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "NSView+SHExtensions.h"

@implementation NSView (SHExtensions)

+ (id)viewFromNib
{
    return [self viewFromNibNamed:NSStringFromClass(self)];
}

+ (id)viewFromNibNamed:(NSString *)nibName
{
    NSNib *nib = [[NSNib alloc] initWithNibNamed:nibName bundle:nil];
    NSArray *objects = nil;
    BOOL success = [nib instantiateWithOwner:self topLevelObjects:&objects];
    if (!success) { return nil; }

    NSView *view = nil;
    for (id object in objects) {
        if ([object isKindOfClass:self]) {
            view = object;
            break;
        }
    }

    return view;
}

@end
