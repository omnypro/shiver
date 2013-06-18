//
//  StreamListView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/18/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "StreamListView.h"

#import "NSColor+Hex.h"

@implementation StreamListView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    [[NSColor colorWithHex:@"#222222"] setFill];
    NSRectFill(dirtyRect);
    [super drawRect:dirtyRect];
}

@end
