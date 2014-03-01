//
//  LoginButtonCell.m
//  Shiver
//
//  Created by Bryan Veloso on 3/1/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "HexColor.h"

#import "LoginButtonCell.h"

@implementation LoginButtonCell

- (id)init
{
    self = [super init];
    if (self == nil) { return nil; }

    [self setBordered:NO];

    return self;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    // Draw an inset rectangle to shorten the button's frame a bit.
    NSRect insetRect = NSInsetRect(cellFrame, 0.0, 1.0);

    NSRect shadowRect = insetRect;
    NSBezierPath *shadowPath = [NSBezierPath bezierPathWithRoundedRect:shadowRect xRadius:2.0 yRadius:2.0];
    [[NSColor colorWithHexString:@"#CDCACD" alpha:1.0] set];
    [shadowPath fill];

    NSRect buttonPath = NSMakeRect(insetRect.origin.x, insetRect.origin.y, insetRect.size.width, insetRect.size.height - 1);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:buttonPath xRadius:2.0 yRadius:2.0];
    [[NSColor colorWithHexString:@"#452D89" alpha:1.0] set];
    [path fill];

    if ([self isHighlighted]) {
        [[NSColor colorWithHexString:@"#0073CE" alpha:1.0] set];
        [path fill];
    }

    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    [style setAlignment:NSCenterTextAlignment];
    NSDictionary *attributes = @{
        NSParagraphStyleAttributeName: style,
        NSForegroundColorAttributeName: [NSColor whiteColor],
        NSFontAttributeName: [NSFont fontWithName:@"HelveticaNeue-Bold" size:11],
    };
    NSAttributedString *buttonTitle = [[NSAttributedString alloc] initWithString:self.title attributes:attributes];
    NSSize titleSize = [buttonTitle size];
    NSRect titleRect = NSMakeRect(0.f, NSMidY(cellFrame) - titleSize.height + 6, cellFrame.size.width, titleSize.height);
    [buttonTitle drawInRect:NSIntegralRect(titleRect)];
}

@end
