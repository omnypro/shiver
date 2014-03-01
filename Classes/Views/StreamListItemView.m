//
//  StreamListViewItem.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "AFImageRequestOperation.h"
#import "Channel.h"
#import "HexColor.h"
#import "NSImage+MGCropExtensions.h"
#import "NSImageView+AFNetworking.h"
#import "Preferences.h"
#import "StreamLogoImageView.h"
#import "StreamPreviewImageView.h"
#import "StreamViewModel.h"

#import "StreamListItemView.h"

@interface StreamListItemView () {
}

@property (nonatomic, strong) NSString *logoURLCache;

@property (weak) IBOutlet NSTextField *gameLabel;
@property (weak) IBOutlet NSTextField *userLabel;
@property (weak) IBOutlet StreamLogoImageView *logo;

@end

@implementation StreamListItemView

+ (StreamListItemView *)initItemStream:(StreamViewModel *)viewModel
{
	NSNib *nib = [[NSNib alloc] initWithNibNamed:NSStringFromClass(self) bundle:nil];
	NSArray *objects = nil;
    [nib instantiateWithOwner:viewModel topLevelObjects:&objects];
	for (id object in objects) {
		if ([object isKindOfClass:[JAListViewItem class]]) {
            [object setSelected:NO];
            [object setViewModel:viewModel];
            [object setupInterface];
            return object;
        }
    }
	return nil;
}

- (void)setupInterface
{
    RAC(self, userLabel.stringValue) = [RACObserve(self, viewModel.channel.displayName) deliverOn:[RACScheduler mainThreadScheduler]];
    RAC(self, gameLabel.stringValue, @"(Unspecified)") = [RACObserve(self, viewModel.channel.game) deliverOn:[RACScheduler mainThreadScheduler]];

    [self.userLabel setTextColor:[NSColor colorWithHexString:@"#FFFFFF" alpha:1]];
    RAC(self, gameLabel.textColor) = [[RACObserve(self, selected) map:^id(id value) {
        return [NSColor colorWithHexString:[value boolValue] ? @"#4A90E2" : @"#7C7C7C" alpha:1];
    }] deliverOn:[RACScheduler mainThreadScheduler]];

    [self refreshLogo];
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
    if (![self.viewModel.logoImageURL.absoluteString isEqualToString:self.logoURLCache]) {
        // Prevent setting the logo unnecessarily.
        NSURLRequest *request = [NSURLRequest requestWithURL:self.viewModel.logoImageURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10];
        [_logo setImageWithURLRequest:request placeholderImage:placeholderImage success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSImage *image) {
            @strongify(self);
            [self.logo setImage:image];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            @strongify(self);
            DDLogError(@"Application (%@): (Error) %@", [self class], error);
        }];

        self.logoURLCache = self.viewModel.logoImageURL.absoluteString;
    }
    else {
        [_logo setImageWithURL:[NSURL URLWithString:self.logoURLCache]];
    }
}

#pragma mark - Drawing Logic

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    NSBezierPath *imageShadowPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(10, 4, 50, 50) xRadius:3.0 yRadius:3.0];
    [[NSColor colorWithHexString:@"#222122" alpha:1.0] set];
    [imageShadowPath fill];

    NSBezierPath *imagePath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(10, 5, 50, 50) xRadius:3.0 yRadius:3.0];
    [[NSColor colorWithHexString:@"#0B0B0B" alpha:1.0] set];
    [imagePath fill];

    if (self.selected) {
        NSBezierPath *selectedPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(8, 3, 54, 54) xRadius:3.0 yRadius:3.0];
        [[NSColor colorWithHexString:@"#0094DA" alpha:1.0] set];
        [selectedPath fill];

        NSBezierPath *imagePath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(10, 5, 50, 50) xRadius:3.0 yRadius:3.0];
        [[NSColor colorWithHexString:@"#0B0B0B" alpha:1.0] set];
        [imagePath fill];
    }
}

- (void) setSelected:(BOOL)isSelected
{
    selected = isSelected;
    [self setNeedsDisplay:YES];
}

@synthesize selected;

@end
