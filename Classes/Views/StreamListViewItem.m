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
#import "NSColor+Hex.h"
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

@property (weak) IBOutlet StreamPreviewImageView *preview;
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

    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:object.channel.status];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineBreakMode:NSLineBreakByWordWrapping];
    [style setMaximumLineHeight:14];
    [attrTitle addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, [attrTitle length])];
    [_titleLabel setAttributedStringValue:attrTitle];

    [_userLabel setStringValue:object.channel.displayName];
    [_userLabel setTextColor:[NSColor colorWithHex:@"#4A4A4A"]];

    [_gameLabel setStringValue:object.game];
    [_gameLabel setTextColor:[NSColor colorWithHex:@"#9D9D9E"]];

    [_viewerCountLabel setStringValue:[NSString stringWithFormat:@"%@", object.viewers]];

    [self refreshLogo];
    [self refreshPreview];
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
            NSLog(@"%@", error);
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
            NSLog(@"%@", error);
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
        NSLog(@"%@", streamURL);
    }
    [[NSWorkspace sharedWorkspace] openURL:streamURL];
}

#pragma mark - Drawing Logic

- (void)drawRect:(NSRect)dirtyRect
{
    // Declare our colors first.
    NSColor *topColor = [NSColor colorWithHex:@"#E6E6E6"];
    NSColor *bottomColor = [NSColor colorWithHex:@"#C6C6C6"];

    // Next, declare the necessary gradient and draw it into the box.
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:bottomColor];
    NSRect rect = NSMakeRect(0, 0, NSWidth(dirtyRect), 110);
    [gradient drawInRect:rect angle:-90];

    // Draw boxes for the highlight and shadow too.
    NSRect highlightRect = NSMakeRect(0, NSHeight(dirtyRect) - 1, NSWidth(dirtyRect), 1);
    [[NSColor whiteColor] setFill];
    NSRectFill(highlightRect);

    NSRect shadowRect = NSMakeRect(0, NSHeight(dirtyRect) - 20, NSWidth(dirtyRect), 1);
    [[NSColor colorWithHex:@"#C0C0C0"] setFill];
    NSRectFill(shadowRect);

}

@end
