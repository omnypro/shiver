//
//  NSView+Animations.h
//  Shiver
//
//  Created by Bryan Veloso on 7/3/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

@interface NSView (Animations)

- (void)addSubview:(NSView *)aView animated:(BOOL)animated;
- (void)removeFromSuperviewAnimated:(BOOL)animated;

@end
