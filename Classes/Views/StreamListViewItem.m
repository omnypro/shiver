//
//  StreamListViewItem.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <EXTScope.h>

#import "AFImageRequestOperation.h"
#import "Channel.h"
#import "HexColor.h"
#import "NSImage+MGCropExtensions.h"
#import "NSImageView+AFNetworking.h"
#import "Preferences.h"
#import "StreamLogoImageView.h"
#import "StreamPreviewImageView.h"

#import "StreamListViewItem.h"

@interface StreamListViewItem () {
    IBOutlet NSTextField *_gameLabel;
    IBOutlet NSTextField *_userLabel;
    IBOutlet NSTextField *_titleLabel;
    IBOutlet NSTextField *_viewerCountLabel;
    IBOutlet NSButton *_redirectButton;
}

@property (weak) IBOutlet StreamLogoImageView *logo;
@property (nonatomic, strong) NSString *logoURLCache;

@property (nonatomic, strong) NSImageView *preview;
@property (nonatomic, strong) NSString *previewURLCache;

- (IBAction)redirectToStream:(id)sender;
@end

@implementation StreamListViewItem

+ (StreamListViewItem *)initItem
{
	NSNib *nib = [[NSNib alloc] initWithNibNamed:NSStringFromClass(self) bundle:nil];
	NSArray *objects = nil;
    [nib instantiateWithOwner:nil topLevelObjects:&objects];
	for (id object in objects) {
		if ([object isKindOfClass:[JAListViewItem class]]) {
            return object;
        }
    }
	return nil;
}

- (void)setObject:(Stream *)object
{
    if (_object == object)
        return;

    _object = object;

    [_titleLabel setAttributedStringValue:[self attributedTitleWithString:_object.channel.status]];

    [_userLabel setStringValue:_object.channel.displayName];
    [_userLabel setTextColor:[NSColor colorWithHexString:@"#BFBFBF" alpha:1]];

    [_gameLabel setStringValue:_object.game];
    [_gameLabel setTextColor:[NSColor colorWithHexString:@"#808080" alpha:1]];

    [_viewerCountLabel setStringValue:[NSString stringWithFormat:@"%@", _object.viewers]];
    [_viewerCountLabel setTextColor:[NSColor colorWithHexString:@"#808080" alpha:1]];

    [self refreshLogo];
    [self refreshPreview];
}

- (NSAttributedString *)attributedTitleWithString:(NSString *)string
{
    NSString *truncatedString = [[string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:truncatedString];

    // Tame the line height first.
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineBreakMode:NSLineBreakByWordWrapping];
    [style setMaximumLineHeight:14];

    // Now add a shadow.
    NSShadow* shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor colorWithHexString:@"#000000" alpha:0.8]];
    [shadow setShadowOffset: NSMakeSize(0.1, -1.1)];
    [shadow setShadowBlurRadius: 2];

    // Put it all together and send it off.
    NSMutableDictionary *attributes = [@{
        NSShadowAttributeName: shadow,
        NSParagraphStyleAttributeName: style
        } mutableCopy];
    [attrTitle addAttributes:attributes range:NSMakeRange(0, [attrTitle length])];
    return attrTitle;
}

- (void)refreshLogo
{
    static NSImage *placeholderImage = nil;

    @weakify(self);
    if (![self.object.channel.logoImageURL.absoluteString isEqualToString:self.logoURLCache]) {
        // Prevent setting the logo unnecessarily.
        NSURLRequest *request = [NSURLRequest requestWithURL:self.object.channel.logoImageURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10];
        [_logo setImageWithURLRequest:request placeholderImage:placeholderImage success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSImage *image) {
            @strongify(self);
            [self.logo setImage:image];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            @strongify(self);
            DDLogError(@"Application (%@): (Error) %@", [self class], error);
        }];

        self.logoURLCache = self.object.channel.logoImageURL.absoluteString;
    }
    else {
        [_logo setImageWithURL:[NSURL URLWithString:self.logoURLCache]];
    }
}

- (void)refreshPreview
{
    static NSImage *placeholderImage = nil;

    @weakify(self);
    if (![self.object.previewImageURL.absoluteString isEqualToString:self.previewURLCache]) {
        // Prevent setting the logo unnecessarily.
        NSURLRequest *request = [NSURLRequest requestWithURL:self.object.previewImageURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10];
        [_preview setImageWithURLRequest:request placeholderImage:placeholderImage success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSImage *image) {
            @strongify(self);
            [self.preview setImage:image];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            @strongify(self);
            DDLogError(@"Application (%@): (Error) %@", [self class], error);
        }];

        self.previewURLCache = self.object.previewImageURL.absoluteString;
    }
    else {
        [_preview setImageWithURL:[NSURL URLWithString:self.previewURLCache]];
    }
}

- (IBAction)redirectToStream:(id)sender
{
    NSURL *streamURL = self.object.channel.url;
    if ([[Preferences sharedPreferences] streamPopupEnabled]) {
        streamURL = [streamURL URLByAppendingPathComponent:@"popout"];
    }
    [[NSWorkspace sharedWorkspace] openURL:streamURL];
}

#pragma mark - Drawing Logic

- (void)drawRect:(NSRect)dirtyRect
{
    // Draw the initial rectangle.
    NSRect initialRect = NSMakeRect(0, 20, NSWidth(dirtyRect), 90);
    [[NSColor colorWithHexString:@"#222222" alpha:1] setFill];
    NSRectFill(initialRect);

    // Draw the sidebar that'll "house" the watch button, viewer count, and
    // part of the avatar.
    NSRect sidebarRect = NSMakeRect(0, -20, 60, 140);
    [[NSColor colorWithHexString:@"#1D1D1D" alpha:1] setFill];
    NSRectFill(sidebarRect);

    // Delcare an inner shadow for the sidebar.
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor colorWithHexString:@"#000000" alpha:0.75]];
    [shadow setShadowOffset:NSMakeSize(0, 0)];
    [shadow setShadowBlurRadius:16];

    NSBezierPath *insetPath = [NSBezierPath bezierPathWithRect:sidebarRect];
    NSRect insetRect = NSInsetRect([insetPath bounds], -shadow.shadowBlurRadius, -shadow.shadowBlurRadius);
    insetRect = NSOffsetRect(insetRect, -shadow.shadowOffset.width, -shadow.shadowOffset.height);
    insetRect = NSInsetRect(NSUnionRect(insetRect, [insetPath bounds]), -1, -1);

    NSBezierPath *insetNegativePath = [NSBezierPath bezierPathWithRect:insetRect];
    [insetNegativePath appendBezierPath:insetPath];
    [insetNegativePath setWindingRule:NSEvenOddWindingRule];

    [NSGraphicsContext saveGraphicsState];
    {
        NSShadow* shadowWithOffset = [shadow copy];
        CGFloat xOffset = shadowWithOffset.shadowOffset.width + round(insetRect.size.width);
        CGFloat yOffset = shadowWithOffset.shadowOffset.height;
        shadowWithOffset.shadowOffset = NSMakeSize(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset));
        [shadowWithOffset set];
        [[NSColor grayColor] setFill];
        [insetPath addClip];

        NSAffineTransform *transform = [NSAffineTransform transform];
        [transform translateXBy:-round(insetRect.size.width) yBy:0];
        [[transform transformBezierPath:insetNegativePath] fill];
    }
    [NSGraphicsContext restoreGraphicsState];
}

@end
