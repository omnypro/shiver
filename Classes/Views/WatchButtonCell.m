//
//  WatchButtonCell.m
//  Shiver
//
//  Created by Bryan Veloso on 6/19/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "WatchButtonCell.h"

#import "HexColor.h"

static const CGFloat bezelMarginTop = 4;
static const CGFloat bezelMarginBottom = 7;
static const CGFloat bezelMarginLeft = 6;
static const CGFloat bezelMarginRight = 8;
static const CGFloat cornerRadius = 2;

@implementation WatchButtonCell

- (void)awakeFromNib
{
    NSMutableAttributedString *buttonTitle = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedTitle];
    [buttonTitle addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, buttonTitle.length)];

    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowOffset:NSMakeSize(0, 1)];
    [shadow setShadowColor:[NSColor colorWithHexString:@"#000000" alpha:0.1]];
    [buttonTitle addAttribute:NSShadowAttributeName value:shadow range:NSMakeRange(0, buttonTitle.length)];
    self.attributedTitle = buttonTitle;
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
    NSRect bezelFrame = frame;
    bezelFrame.origin.y += bezelMarginTop;
    bezelFrame.size.height -= bezelMarginTop + bezelMarginBottom;
    bezelFrame.origin.x += bezelMarginLeft;
    bezelFrame.size.width -= bezelMarginLeft + bezelMarginRight;

    NSRect strokeRect = NSInsetRect(bezelFrame, 0.5, 0.5);
    NSBezierPath *strokePath = [NSBezierPath bezierPathWithRoundedRect:strokeRect xRadius:cornerRadius yRadius:cornerRadius];

    {
        [[NSGraphicsContext currentContext] saveGraphicsState];
        [strokePath addClip];

        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithHexString:@"#5ABC0E" alpha:1] endingColor:[NSColor colorWithHexString:@"#93DF22" alpha:1]];
        [gradient drawInRect:bezelFrame angle:self.isHighlighted ? 90 : 270];

        [[NSGraphicsContext currentContext] restoreGraphicsState];
    }

    {
        [[NSGraphicsContext currentContext] saveGraphicsState];
        CGContextSetBlendMode([[NSGraphicsContext currentContext] graphicsPort], kCGBlendModeOverlay);

        [[NSColor colorWithHexString:@"#FFFFFF" alpha:0.1] setStroke];
        [[NSBezierPath bezierPathWithRoundedRect:NSOffsetRect(strokeRect, 0, 1) xRadius:cornerRadius yRadius:cornerRadius] stroke];

        [[NSGraphicsContext currentContext] restoreGraphicsState];
    }

    [[NSColor colorWithHexString:@"#000000" alpha:0.5] setStroke];
    [strokePath stroke];
}

@end
