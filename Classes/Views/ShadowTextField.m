//
//  ShadowTextField.m
//  Shiver
//
//  Created by Bryan Veloso on 6/18/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "ShadowTextField.h"

@implementation ShadowTextField

- (void)setup
{
    self.shadow = [[NSShadow alloc] init];
    self.shadow.shadowOffset = NSMakeSize(0.0, -1.0);
    self.shadow.shadowColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.75];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self == nil)
        return nil;

    [self setup];

    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (self.shadow == nil) {
        [super drawRect:dirtyRect];
        return;
    }

    NSMutableDictionary *attributes = [[self.attributedStringValue attributesAtIndex:0 effectiveRange:NULL] mutableCopy];
    [attributes setObject:self.shadow forKey:NSShadowAttributeName];

    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:self.stringValue attributes:attributes];
    [attrString drawInRect:dirtyRect];
}

@end
