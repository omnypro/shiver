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

    [self.liveSinceLabel setTextColor:[NSColor colorWithHexString:@"#9B9B9B"]];
    [self.broadcastLabel setTextColor:[NSColor colorWithHexString:@"#AFB7B8"]];

    [self drawBackground];
    [self drawHeader];
    [self drawFooter];
    [self drawWebView];
    [self drawPlayerBar];
}

- (void)drawBackground
{
    // Draw the view's background and header rectangle. Fill it.
    NSGradient *backgroundGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithHexString:@"#242428"] endingColor:[NSColor colorWithHexString:@"#151619"]];
    NSBezierPath *backgroundPath = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect([self bounds], 0.0, 0.0) cornerRadius:2.0 inCorners:OSBottomRightCorner];
    [backgroundGradient drawInBezierPath:backgroundPath angle:-90];

    NSBezierPath *overlayPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(5, 6, self.bounds.size.width - 10, self.bounds.size.height) cornerRadius:2.0 inCorners:OSBottomRightCorner];
    [[NSColor colorWithHexString:@"#101113"] set];
    [overlayPath fill];
}

- (void)drawHeader
{
    // Draw the view's header top border rectangle.
    NSGradient *headerGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithHexString:@"#161719"] endingColor:[NSColor colorWithHexString:@"#171719"]];
    NSBezierPath *headerPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0, self.bounds.size.height - 10, self.bounds.size.width, 10)];
    [headerGradient drawInBezierPath:headerPath angle:-90];

    NSBezierPath *closeBoxPath = [NSBezierPath bezierPathWithRect:NSMakeRect(self.bounds.size.width - 40, self.bounds.size.height - 10, 40, 10)];
    [[NSColor colorWithHexString:@"#141417" alpha:1.0] set];
    [closeBoxPath fill];

    NSRect borderRect = NSMakeRect(0, self.bounds.size.height - 10, self.bounds.size.width, 3);
    [[NSColor colorWithHexString:@"#452D89" alpha:1.0] setFill];
    NSRectFill(borderRect);

    NSRect borderHighlightRect = NSMakeRect(0, self.bounds.size.height - 8, self.bounds.size.width, 1);
    [[NSColor colorWithHexString:@"#5C3DAF" alpha:1.0] setFill];
    NSRectFill(borderHighlightRect);

    NSRect borderShadowRect = NSMakeRect(0, self.bounds.size.height - 11, self.bounds.size.width, 1);
    [[NSColor colorWithHexString:@"#151518" alpha:1.0] setFill];
    NSRectFill(borderShadowRect);
}

- (void)drawFooter
{
    // Draw the view's footer rectangle and fill it with white.
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithHexString:@"#FFFFFF"] endingColor:[NSColor colorWithHexString:@"#F7F7F7"]];
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, self.bounds.size.width, 110)];
    [gradient drawInBezierPath:path angle:-90];
}

- (void)drawWebView
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

    // Initialize the web view's shadow.
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor colorWithHexString:@"#000000" alpha:0.8]];
    [shadow setShadowOffset:NSMakeSize(0.0, 0.0)];
    [shadow setShadowBlurRadius:4];

    NSBezierPath *webViewPath = [NSBezierPath bezierPathWithRect:NSMakeRect(10, 123, self.bounds.size.width - 20, self.bounds.size.height - 123)];

    // Draw the gradient into the player and the shadow below it.
    [NSGraphicsContext saveGraphicsState];
    {
        [shadow set];
        CGContextBeginTransparencyLayer(context, NULL);
        [[NSColor colorWithHexString:@"#000000"] setFill];
        [webViewPath fill];
        CGContextEndTransparencyLayer(context);
    }
    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawPlayerBar
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

    // Initialize the player bar and its gradient.
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithHexString:@"#2E2F30"] endingColor:[NSColor colorWithHexString:@"#17191B"]];
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(10, 93, self.bounds.size.width - 20, 29) cornerRadius:2.0 inCorners:OSBottomLeftCorner | OSBottomRightCorner];

    // Initialize the player bar's shadow.
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor colorWithHexString:@"#000000" alpha:0.4]];
    [shadow setShadowOffset:NSMakeSize(0.0, -2.0)];
    [shadow setShadowBlurRadius:4];

    // Draw the gradient into the player and the shadow below it.
    [NSGraphicsContext saveGraphicsState];
    {
        [shadow set];
        CGContextBeginTransparencyLayer(context, NULL);
        [gradient drawInBezierPath:path angle:-90];
        CGContextEndTransparencyLayer(context);
    }
    [NSGraphicsContext restoreGraphicsState];

    // Initialize and draw the player bar's highlight line.
    NSRect highlightRect = NSMakeRect(10, 121, self.bounds.size.width - 20, 1);
    [[NSColor colorWithHexString:@"#404043" alpha:1.0] setFill];
    NSRectFill(highlightRect);
}

- (NSAttributedString *)attributedStatusWithString:(NSString *)string
{
    NSString *truncatedString = [[string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
    NSMutableAttributedString *attrStatus = [[NSMutableAttributedString alloc] initWithString:truncatedString];

    // Tame the line height first.
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineBreakMode:NSLineBreakByWordWrapping];
    [style setMaximumLineHeight:20];

    // Give it a shadow.
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
    [shadow setShadowColor:[NSColor colorWithHexString:@"#FFFFFF"]];

    // Send it off.
    NSMutableDictionary *attributes = [@{
        NSForegroundColorAttributeName: [NSColor colorWithHexString:@"#4A4A4A"],
        NSShadowAttributeName: shadow,
        NSParagraphStyleAttributeName: style,
    } mutableCopy];
    [attrStatus addAttributes:attributes range:NSMakeRange(0, [attrStatus length])];
    return attrStatus;
}

@end
