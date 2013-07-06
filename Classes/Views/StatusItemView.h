//
//  StatusItemView.h
//  Shiver
//
//  Created by Bryan Veloso on 7/5/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface StatusItemView : NSView <NSWindowDelegate>

@property (nonatomic, assign, getter=isActive) BOOL active;
@property (nonatomic, assign) BOOL animated;
@property (nonatomic, strong) NSImage *image;
@property (nonatomic, strong) NSImage *alternateImage;

@property (nonatomic, strong) id target;
@property (nonatomic) SEL action;

- (id)initWithWindow:(NSWindow *)window image:(NSImage *)image alternateImage:(NSImage *)alternateImage label:(NSString *)label;
- (void)setTitle:(NSString *)title;

@end
