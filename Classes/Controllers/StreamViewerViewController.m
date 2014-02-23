//
//  StreamViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 2/14/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import <WebKit/WebKit.h>

#import "MainWindowController.h"
#import "HexColor.h"
#import "NSAttributedString+CCLFormat.h"
#import "StreamViewModel.h"
#import "UserImageView.h"

#import "StreamViewerViewController.h"

@interface StreamViewerViewController ()

@property (nonatomic, strong) MainWindowController *windowController;
@property (nonatomic, strong) StreamViewModel *stream;

@property (weak) IBOutlet NSButton *profileButton;
@property (weak) IBOutlet NSButton *chatButton;
@property (weak) IBOutlet NSTextField *liveSinceLabel;
@property (weak) IBOutlet NSTextField *statusLabel;
@property (weak) IBOutlet NSImageView *logo;

@end

@implementation StreamViewerViewController

- (id)initWithViewModel:(RVMViewModel *)viewModel nibName:(NSString *)nibName bundle:(NSBundle *)bundle
{
    self = [super initWithViewModel:viewModel nibName:nibName bundle:bundle];
    if (self == nil) { return nil; }

    _windowController = [[NSApp delegate] windowController];

    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    RAC(self, statusLabel.attributedStringValue, @"") = [RACObserve(self, stream.status)
        map:^id(NSString *value) {
            if (value) { return [self attributedStatusWithString:value]; }
            else { return @""; }
        }];

    RAC(self, logo.image) = RACObserve(self, stream.logo);

    [self.liveSinceLabel setTextColor:[NSColor colorWithHexString:@"#9B9B9B" alpha:1]];
    RAC(self, liveSinceLabel.stringValue, @"") = [RACObserve(self, stream.liveSince)
        map:^id(NSString *value) {
            if (value) { return [NSString stringWithFormat:@"Live for %@", value]; }
            else { return @""; }
        }];

    // Observers for IBOutlets that are part of the title bar's view.
    // This is part of my hack to ensure that I don't have to redraw the
    // entrire window, title bar, etc.
    RAC(self, windowController.gameLabel.attributedStringValue, @"") = [RACSignal
        combineLatest:@[RACObserve(self, stream.displayName), RACObserve(self, stream.game)]
        reduce:^id(NSString *displayName, NSString *game) {
            if (displayName && game) { return [self attributedStringWithName:displayName game:game]; }
            else if (displayName) { return [self attributedStringWithName:displayName]; }
            else { return @""; }
        }];
    RAC(self, windowController.viewersLabel.attributedStringValue) = [RACObserve(self, stream.viewers)
        map:^id(NSNumber *value) {
            if (value) { return [self attributedViewersWithNumber:value]; }
            else { return @""; }
        }];

    [_webView setFrameLoadDelegate:self];
}

- (void)setSelectedStream:(StreamViewModel *)stream {
    self.stream = stream;

    NSURLRequest *request = [NSURLRequest requestWithURL:stream.hlsURL];
    [[_webView mainFrame] loadRequest:request];
}

#pragma mark - Appearance

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

#pragma mark - WebFrameLoadDelegate Methods

- (BOOL)webView:(WebView *)webView shouldChangeSelectedDOMRange:(DOMRange *)currentRange toDOMRange:(DOMRange *)proposedRange affinity:(NSSelectionAffinity)selectionAffinity stillSelecting:(BOOL)flag
{
    return NO; // Prevent the selection of content.
}

@end
