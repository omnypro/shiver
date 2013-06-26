//
//  NSView+SHExtensions.h
//  Shiver
//
//  Created by Bryan Veloso on 6/25/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSView (SHExtensions)

+ (id)viewFromNib;
+ (id)viewFromNibNamed:(NSString *)nibName;

@end
