//
//  ChatButtonCell.m
//  Shiver
//
//  Created by Bryan Veloso on 2/22/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "HexColor.h"

#import "FollowButtonCell.h"

@implementation FollowButtonCell

- (id)init
{
    self = [super init];
    if (self == nil) { return nil; }

    [self setBordered:NO];

    return self;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:cellFrame xRadius:3.0 yRadius:3.0];
    [path setLineWidth:1.0];
    [[NSColor colorWithHexString:@"#CCC0E1" alpha:1.0] set];
    [path stroke];

    if ([self isHighlighted]) {
        [[NSColor colorWithHexString:@"#ABDBF3" alpha:1.0] set];
        [path stroke];
    }

    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    [style setAlignment:NSCenterTextAlignment];
    NSDictionary *attributes = @{
        NSParagraphStyleAttributeName: style,
        NSForegroundColorAttributeName: self.isHighlighted ? [NSColor colorWithHexString:@"#58B8E6" alpha:1.0] : [NSColor colorWithHexString:@"#9983C4" alpha:1.0],
        NSFontAttributeName: [NSFont fontWithName:@"HelveticaNeue-Bold" size:13],
    };
    NSAttributedString *buttonTitle = [[NSAttributedString alloc] initWithString:self.title attributes:attributes];
    NSSize titleSize = [buttonTitle size];
    NSRect titleRect = NSMakeRect(0.f, NSMidY(cellFrame) - titleSize.height + 8, cellFrame.size.width, titleSize.height);
    [buttonTitle drawInRect:NSIntegralRect(titleRect)];
}

@end
