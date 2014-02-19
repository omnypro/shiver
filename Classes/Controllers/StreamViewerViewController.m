//
//  StreamViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 2/14/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import <WebKit/WebKit.h>

#import "StreamViewModel.h"

#import "StreamViewerViewController.h"

@interface StreamViewerViewController ()

@property (nonatomic, strong) StreamViewModel *stream;
@property (weak) IBOutlet NSTextField *nameLabel;
@property (weak) IBOutlet NSTextField *statusLabel;
@property (weak) IBOutlet NSTextField *viewersLabel;

@end

@implementation StreamViewerViewController

- (void)awakeFromNib
{
    [super awakeFromNib];

    [_webView setFrameLoadDelegate:self];

    RAC(self, nameLabel.stringValue, @"") = [RACSignal
        combineLatest:@[RACObserve(self, stream.displayName), RACObserve(self, stream.game)]
        reduce:^id(NSString *displayName, NSString *game) {
            if (displayName && game) { return [NSString stringWithFormat:@"%@ playing %@", displayName, game]; }
            else { return @""; }
        }];
    RAC(self, statusLabel.attributedStringValue, @"") = [RACObserve(self, stream.status)
        map:^id(NSString *value) {
            if (value) { return [self attributedStatusWithString:value]; }
            else { return @""; }
        }];
    RAC(self, viewersLabel.stringValue, @"") = RACObserve(self, stream.viewers);
}

- (void)setSelectedStream:(StreamViewModel *)stream {
    self.stream = stream;

    NSURLRequest *request = [NSURLRequest requestWithURL:stream.hlsURL];
    [[_webView mainFrame] loadRequest:request];
}

#pragma mark - Appearance

- (NSAttributedString *)attributedStatusWithString:(NSString *)string
{
    NSString *truncatedString = [[string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
    NSMutableAttributedString *attrStatus = [[NSMutableAttributedString alloc] initWithString:truncatedString];

    // Tame the line height first.
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineBreakMode:NSLineBreakByWordWrapping];
    [style setMaximumLineHeight:16];

    // Send it off.
    NSMutableDictionary *attributes = [@{
        NSParagraphStyleAttributeName: style
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
