//
//  StreamViewerView.m
//  Shiver
//
//  Created by Bryan Veloso on 2/21/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "HexColor.h"
#import "NSAttributedString+CCLFormat.h"
#import "NSBezierPath-PXRoundedRectangleAdditions.h"

#import "StreamViewerView.h"

@implementation StreamViewerView

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];

    [self.liveSinceLabel setTextColor:[NSColor colorWithHexString:@"#9B9B9B" alpha:1]];
    [self.broadcastLabel setTextColor:[NSColor colorWithHexString:@"#AFB7B8" alpha:1]];

    // Draw the view's header rectangle and fill it.
    NSColor *contentTopColor = [NSColor colorWithHexString:@"#171719" alpha:1.0];
    NSColor *contentBottomColor = [NSColor colorWithHexString:@"#0B0C0D" alpha:1.0];
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:contentTopColor endingColor:contentBottomColor];
    NSBezierPath *contentPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 110, self.bounds.size.width, self.bounds.size.height - 10)];
    [gradient drawInBezierPath:contentPath angle:-90];

    // Draw the view's header top border rectangle.
    NSRect borderRect = NSMakeRect(0, self.bounds.size.height - 13, self.bounds.size.width, 3);
    [[NSColor colorWithHexString:@"#452D89" alpha:1.0] setFill];
    NSRectFill(borderRect);

    NSRect borderHighlightRect = NSMakeRect(0, self.bounds.size.height - 11, self.bounds.size.width, 1);
    [[NSColor colorWithHexString:@"#5C3DAF" alpha:1.0] setFill];
    NSRectFill(borderHighlightRect);

    NSRect borderShadowRect = NSMakeRect(0, self.bounds.size.height - 15, self.bounds.size.width, 1);
    [[NSColor colorWithHexString:@"#151518" alpha:1.0] setFill];
    NSRectFill(borderShadowRect);

    NSColor *headerTopColor = [NSColor colorWithHexString:@"#161719" alpha:1.0];
    NSColor *headerBottomColor = [NSColor colorWithHexString:@"171719" alpha:1.0];
    NSGradient *headerGradient = [[NSGradient alloc] initWithStartingColor:headerTopColor endingColor:headerBottomColor];
    NSBezierPath *headerPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0, self.bounds.size.height - 10, self.bounds.size.width, 10)];
    [headerGradient drawInBezierPath:headerPath angle:-90];

    // Draw the view's footer rectangle and fill it with white.
    NSRect footerRect = NSMakeRect(0, 0, self.bounds.size.width, 110);
    [[NSColor colorWithHexString:@"#FFFFFF" alpha:1.0] setFill];
    NSRectFill(footerRect);

    // Draw the player bar.
    NSColor *playerTopColor = [NSColor colorWithHexString:@"#2E2F30" alpha:1.0];
    NSColor *playerBottomColor = [NSColor colorWithHexString:@"#17191B" alpha:1.0];
    NSGradient *playerGradient = [[NSGradient alloc] initWithStartingColor:playerTopColor endingColor:playerBottomColor];
    NSRect playerRect = NSMakeRect(10, 93, self.bounds.size.width - 20, 29);
    NSBezierPath *playerPath = [NSBezierPath bezierPathWithRoundedRect:playerRect cornerRadius:2.0 inCorners:OSBottomLeftCorner | OSBottomRightCorner];
    [playerGradient drawInBezierPath:playerPath angle:-90];

    NSRect playerHighlightRect = NSMakeRect(10, 121, self.bounds.size.width - 20, 1);
    [[NSColor colorWithHexString:@"#404043" alpha:1.0] setFill];
    NSRectFill(playerHighlightRect);
}

- (NSAttributedString *)attributedStatusWithString:(NSString *)string
{
    NSString *truncatedString = [[string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
    NSMutableAttributedString *attrStatus = [[NSMutableAttributedString alloc] initWithString:truncatedString];

    // Tame the line height first.
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineBreakMode:NSLineBreakByWordWrapping];
    [style setMaximumLineHeight:20];

    // Send it off.
    NSMutableDictionary *attributes = [@{
        NSForegroundColorAttributeName: [NSColor colorWithHexString:@"#4A4A4A" alpha:1.0],
        NSParagraphStyleAttributeName: style,
    } mutableCopy];
    [attrStatus addAttributes:attributes range:NSMakeRange(0, [attrStatus length])];
    return attrStatus;
}

@end
