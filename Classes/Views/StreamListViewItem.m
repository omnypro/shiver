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
#import "StreamLogoImageView.h"
#import "StreamPreviewImageView.h"

#import "StreamListViewItem.h"

@interface StreamListViewItem ()

@property (weak) IBOutlet StreamLogoImageView *logo;
@property (weak) IBOutlet StreamPreviewImageView *preview;
@property (weak) IBOutlet NSTextField *gameLabel;
@property (weak) IBOutlet NSTextField *userLabel;
@property (weak) IBOutlet NSTextField *titleLabel;
@property (weak) IBOutlet NSTextField *viewerCountLabel;
@property (weak) IBOutlet NSButton *redirectButton;

@property (nonatomic, strong) NSString *logoURLCache;
@property (nonatomic, strong) NSString *previewURLCache;

- (IBAction)redirectToStream:(id)sender;

@end

@implementation StreamListViewItem

+ (StreamListViewItem *)initItem
{
    static NSNib *nib = nil;
    if(nib == nil) {
        nib = [[NSNib alloc] initWithNibNamed:NSStringFromClass(self) bundle:nil];
    }

    NSArray *objects = nil;
    [nib instantiateWithOwner:nil topLevelObjects:&objects];
    for(id object in objects) {
        if ([object isKindOfClass:self]) {
            return object;
        }
    }

    NSAssert1(NO, @"No view of class %@ found.", NSStringFromClass(self));
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
    [self.titleLabel setAttributedStringValue:attrTitle];

    [self.userLabel setStringValue:object.channel.displayName];
    [self.userLabel setTextColor:[NSColor colorWithHex:@"#4A4A4A"]];

    [self.gameLabel setStringValue:object.game];
    [self.gameLabel setTextColor:[NSColor colorWithHex:@"#9D9D9E"]];

    [self.viewerCountLabel setStringValue:[NSString stringWithFormat:@"%@", object.viewers]];

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
        [self.preview setImageWithURLRequest:request placeholderImage:placeholderImage success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSImage *image) {
            @strongify(self);
            [self.logo setImage:image];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            NSLog(@"%@", error);
        }];

        self.logoURLCache = self.object.channel.logoImageURL.absoluteString;
    }
    else {
        [self.logo setImageWithURL:[NSURL URLWithString:self.logoURLCache]];
    }
}

- (void)refreshPreview
{
    static NSImage *placeholderImage = nil;

    @weakify(self);
    if (![self.object.previewImageURL.absoluteString isEqualToString:self.previewURLCache]) {
        // Prevent setting the logo unnecessarily.
        NSURLRequest *request = [NSURLRequest requestWithURL:self.object.previewImageURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10];
        [self.preview setImageWithURLRequest:request placeholderImage:placeholderImage success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSImage *image) {
            @strongify(self);
            [self.preview setImage:image];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            NSLog(@"%@", error);
        }];

        self.previewURLCache = self.object.previewImageURL.absoluteString;
    }
    else {
        [self.preview setImageWithURL:[NSURL URLWithString:self.previewURLCache]];
    }
}

- (IBAction)redirectToStream:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:self.object.channel.url];
}

#pragma mark - Drawing Logic

- (void)drawRect:(NSRect)dirtyRect
{
    // Abstracted attributes.
    CGFloat cornerRadius = 2;
    NSRect frame = dirtyRect;

    // Declare our colors first.
    NSColor *topColor = [NSColor colorWithCalibratedRed:0.902 green:0.906 blue:0.91 alpha:1];
    NSColor *bottomColor = [NSColor colorWithCalibratedRed:0.827 green:0.831 blue:0.835 alpha:1];

    // Next, declare the necessary gradient and shadow.
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:bottomColor];
    NSShadow *innerShadow = [[NSShadow alloc] init];
    [innerShadow setShadowColor:[NSColor whiteColor]];
    [innerShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
    [innerShadow setShadowBlurRadius:0];

    // Draw the box.
    NSRect rect = NSMakeRect(5, 0, NSWidth(frame) - 10, 110);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:cornerRadius yRadius:cornerRadius];
    [gradient drawInBezierPath:path angle:-90];

    NSRect borderRect = NSInsetRect([path bounds], -innerShadow.shadowBlurRadius, -innerShadow.shadowBlurRadius);
    borderRect = NSOffsetRect(borderRect, -innerShadow.shadowOffset.width, -innerShadow.shadowOffset.height);
    borderRect = NSInsetRect(NSUnionRect(borderRect, [path bounds]), -1, -1);

    NSBezierPath *negativePath = [NSBezierPath bezierPathWithRect:borderRect];
    [negativePath appendBezierPath:path];
    [negativePath setWindingRule:NSEvenOddWindingRule];

    [NSGraphicsContext saveGraphicsState];
    {
        NSShadow *shadowWithOffset = [innerShadow copy];
        CGFloat xOffset = shadowWithOffset.shadowOffset.width + round(borderRect.size.width);
        CGFloat yOffset = shadowWithOffset.shadowOffset.height;
        shadowWithOffset.shadowOffset = NSMakeSize(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset));
        [shadowWithOffset set];
        [[NSColor grayColor] setFill];
        [path addClip];
        NSAffineTransform *transform = [NSAffineTransform transform];
        [transform translateXBy:-round(borderRect.size.width) yBy: 0];
        [[transform transformBezierPath:negativePath] fill];
    }
    [NSGraphicsContext restoreGraphicsState];
}

@end
