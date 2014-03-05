//
//  TitleView.m
//  Shiver
//
//  Created by Bryan Veloso on 2/21/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "HexColor.h"
#import "NSAttributedString+CCLFormat.h"
#import "NSBezierPath-PXRoundedRectangleAdditions.h"

#import "TitleView.h"

@implementation TitleView

- (void)setIsActive:(BOOL)value
{
    _isActive = value;
    [self setNeedsDisplay:YES];
    [self setNeedsLayout:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];

    // Draw the view's right shadow.
    NSBezierPath *shadowPath = [NSBezierPath bezierPathWithRect:NSMakeRect(238, 0, 2, self.bounds.size.height)];
    [[NSColor colorWithCalibratedWhite:0 alpha:0.25] setFill];
    [shadowPath fill];

    if (self.isActive) {
        [self drawActive];
    } else {
        [self drawInactive];
    }
}

- (void)drawInactive
{
    // Draw the view's background.
    NSColor *background = [NSColor colorWithHexString:@"#242428"];
    NSBezierPath *backgroundPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(240, 0, self.bounds.size.width - 240, self.bounds.size.height) cornerRadius:3.0 inCorners:OSTopRightCorner];
    [background set];
    [backgroundPath fill];

    // Draw the overlaying rectangle.
    NSColor *overlay = [NSColor colorWithHexString:@"#101113"];
    NSBezierPath *overlayPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(245, 0, self.bounds.size.width - 250, self.bounds.size.height - 5) cornerRadius:2.0 inCorners:OSTopRightCorner];
    [overlay set];
    [overlayPath fill];

    NSRect titleHighlightRect = NSMakeRect(240, 37, self.bounds.size.width - 242, 1);
    [[NSColor colorWithHexString:@"#38393C" alpha:1.0] setFill];
    NSRectFill(titleHighlightRect);
}

- (void)drawActive
{
    // Draw the view's footer rectangle and fill it with a gradient.
    NSColor *titleTopColor = [NSColor colorWithHexString:@"#2A2B2E" alpha:1.0];
    NSColor *titleBottomColor = [NSColor colorWithHexString:@"#161719" alpha:1.0];
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:titleTopColor endingColor:titleBottomColor];
    NSBezierPath *titlePath = [NSBezierPath bezierPathWithRect:NSMakeRect(240, 0, self.bounds.size.width - 240 - 40, self.bounds.size.height)];
    [gradient drawInBezierPath:titlePath angle:-90];

    NSColor *titleSideHighlightTopColor = [NSColor colorWithHexString:@"#36373C" alpha:1.0];
    NSColor *titleSideHighlightBottomColor = [NSColor colorWithHexString:@"#232427" alpha:1.0];
    NSGradient *titleSizeHighlightGradient = [[NSGradient alloc] initWithStartingColor:titleSideHighlightTopColor endingColor:titleSideHighlightBottomColor];
    NSBezierPath *titleSideHighlightRect = [NSBezierPath bezierPathWithRect:NSMakeRect(self.bounds.size.width - 41, 0, 1, 37)];
    [titleSizeHighlightGradient drawInBezierPath:titleSideHighlightRect angle:-90];

    NSRect titleHighlightRect = NSMakeRect(240, 37, self.bounds.size.width - 242, 1);
    [[NSColor colorWithHexString:@"#4B4C51" alpha:1.0] setFill];
    NSRectFill(titleHighlightRect);

    // Draw the box that will contain the close button.
    NSBezierPath *closeBoxPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(self.bounds.size.width - 40, 0, 40, self.bounds.size.height) cornerRadius:3 inCorners:OSTopRightCorner];
    [[NSColor colorWithHexString:@"#141417" alpha:1.0] set];
    [closeBoxPath fill];

    NSRect closeBoxHighlightRect = NSMakeRect(self.bounds.size.width - 40, 37, 38, 1);
    [[NSColor colorWithHexString:@"#25272A" alpha:1.0] setFill];
    NSRectFill(closeBoxHighlightRect);

    NSRect closeBoxShadowRect = NSMakeRect(self.bounds.size.width - 40, 0, 1, self.bounds.size.height - 1);
    [[NSColor colorWithHexString:@"#101012" alpha:1.0] set];
    NSRectFill(closeBoxShadowRect);
}

- (NSAttributedString *)attributedStringWithName:(NSString *)name
{
    NSAttributedString *attrName = [[NSAttributedString alloc] initWithString:name attributes:@{
        NSFontAttributeName: [NSFont fontWithName:@"HelveticaNeue-Bold" size:13.0],
        NSForegroundColorAttributeName: [NSColor colorWithHexString:@"#FFFFFF" alpha:1.0],
    }];

    NSAttributedString *attrPlayingUnspecified = [[NSAttributedString alloc] initWithString:@"playing an unspecified game" attributes:@{
        NSForegroundColorAttributeName: [NSColor colorWithHexString:@"#C7C7C7" alpha:1.0],
    }];

    NSAttributedString *attrString = [NSAttributedString attributedStringWithFormat:@"%@ %@", attrName, attrPlayingUnspecified];
    return attrString;
}

- (NSAttributedString *)attributedStringWithName:(NSString *)name game:(NSString *)game
{
    NSAttributedString *attrName = [[NSAttributedString alloc] initWithString:name attributes:@{
        NSFontAttributeName: [NSFont fontWithName:@"HelveticaNeue-Bold" size:13.0],
        NSForegroundColorAttributeName: [NSColor colorWithHexString:@"#FFFFFF" alpha:1.0],
    }];

    NSAttributedString *attrPlaying = [[NSAttributedString alloc] initWithString:@"playing" attributes:@{
        NSForegroundColorAttributeName: [NSColor colorWithHexString:@"#C7C7C7" alpha:1.0],
    }];

    NSAttributedString *attrGame = [[NSAttributedString alloc] initWithString:game attributes:@{
        NSFontAttributeName: [NSFont fontWithName:@"HelveticaNeue-Bold" size:13.0],
        NSForegroundColorAttributeName: [NSColor colorWithHexString:@"#FFFFFF" alpha:1.0],
    }];

    NSAttributedString *attrString = [NSAttributedString attributedStringWithFormat:@"%@ %@ %@", attrName, attrPlaying, attrGame];
    return attrString;
}

- (NSAttributedString *)attributedViewersWithNumber:(NSNumber *)number
{
    NSAttributedString *attrCount = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", number] attributes:@{
        NSFontAttributeName: [NSFont fontWithName:@"HelveticaNeue-Bold" size:13.0],
        NSForegroundColorAttributeName: [NSColor colorWithHexString:@"#C7C7C7" alpha:1.0],
    }];

    NSAttributedString *attrViewers = [[NSAttributedString alloc] initWithString:@"viewers" attributes:@{
        NSForegroundColorAttributeName: [NSColor colorWithHexString:@"#7C7C7C" alpha:1.0],
    }];

    NSAttributedString *attrString = [NSAttributedString attributedStringWithFormat:@"%@ %@", attrCount, attrViewers];
    return attrString;
}

@end
