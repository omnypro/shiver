//
//  StreamViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 2/14/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import <WebKit/WebKit.h>

#import "EmptyViewerView.h"
#import "MainWindowController.h"
#import "HexColor.h"
#import "StreamViewModel.h"
#import "StreamViewerView.h"
#import "TitleView.h"
#import "UserImageView.h"

#import "StreamViewerViewController.h"

@interface StreamViewerViewController ()

@property (nonatomic, strong) MainWindowController *windowController;
@property (nonatomic, strong) StreamViewModel *stream;
@property (nonatomic, strong) NSURL *profileURL;

@property (nonatomic, strong) EmptyViewerView *emptyView;
@property (nonatomic, strong) StreamViewerView *viewerView;
@property (nonatomic, strong) TitleView *titleView;

@end

@implementation StreamViewerViewController

- (id)initWithViewModel:(RVMViewModel *)viewModel nibName:(NSString *)nibName bundle:(NSBundle *)bundle
{
    self = [super initWithViewModel:viewModel nibName:nibName bundle:bundle];
    if (self == nil) { return nil; }

    _windowController = [[NSApp delegate] windowController];

    _titleView = [_windowController titleView];
    _viewerView = [StreamViewerView init];

    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    @weakify(self);

    [[[RACObserve(self, stream) filter:^BOOL(id value) {
        return (value == nil);
    }] deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
        @strongify(self);
        NSLog(@"we don't have a stream...");
        self.emptyView = [EmptyViewerView init];
        [self.view addSubview:self.emptyView];
        [self.titleView setIsActive:NO];
    }];

    [[[[RACObserve(self, stream) filter:^BOOL(id value) {
        return (value != nil);
    }] take:1] deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
        @strongify(self);
        NSLog(@"we have a stream...");
        [self.emptyView removeFromSuperview];
        [self.titleView setIsActive:YES];
    }];


    RAC(self, viewerView.statusLabel.attributedStringValue, @"") = [RACObserve(self, stream.status)
        map:^id(NSString *value) {
            @strongify(self);
            if (value) { return [self.viewerView attributedStatusWithString:value]; }
            else { return @""; }
        }];

    RAC(self, viewerView.logo.image) = [RACObserve(self, stream.logoImageURL)
        map:^id(NSURL *url) {
            return [[NSImage alloc] initWithContentsOfURL:url];
        }];

    RAC(self, viewerView.liveSinceLabel.stringValue, @"") = [RACObserve(self, stream.liveSince)
        map:^id(NSString *value) {
            if (value) { return [NSString stringWithFormat:@"Live for %@", value]; }
            else { return @""; }
        }];

    // Observers for IBOutlets that are part of the title bar's view.
    // This is part of my hack to ensure that I don't have to redraw the
    // entrire window, title bar, etc.
    RAC(self, titleView.gameLabel.attributedStringValue, @"") = [RACSignal
        combineLatest:@[RACObserve(self, stream.displayName), RACObserve(self, stream.game)]
        reduce:^id(NSString *displayName, NSString *game) {
            @strongify(self);
            if (displayName && game) { return [self.titleView attributedStringWithName:displayName game:game]; }
            else if (displayName) { return [self.titleView attributedStringWithName:displayName]; }
            else { return @""; }
        }];
    RAC(self, titleView.viewersLabel.attributedStringValue) = [RACObserve(self, stream.viewers)
        map:^id(NSNumber *value) {
            if (value) { return [self.titleView attributedViewersWithNumber:value]; }
            else { return @""; }
        }];

    RAC(self, profileURL) = [RACObserve(self, stream.name)
        map:^id(NSString *name) {
            return [NSURL URLWithString:[NSString stringWithFormat:@"http://twitch.tv/%@/profile", name]];
        }];

    [_webView setFrameLoadDelegate:self];
}

- (void)setSelectedStream:(StreamViewModel *)stream {
    self.stream = stream;

    NSURLRequest *request = [NSURLRequest requestWithURL:stream.hlsURL];
    [[_webView mainFrame] loadRequest:request];
}

#pragma mark - WebFrameLoadDelegate Methods

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    // We manipulate the <video> element via Javascript to hide the native
    // controls so we can implement our own.
    WebScriptObject *win = [self.webView windowScriptObject];
    [win evaluateWebScript:[NSString stringWithFormat:@"video = document.getElementById('content_player')"]];
    [win evaluateWebScript:[NSString stringWithFormat:@"video.removeAttribute('controls');"]];
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
    return nil; // Hide the contextual menu.
}

- (BOOL)webView:(WebView *)webView shouldChangeSelectedDOMRange:(DOMRange *)currentRange toDOMRange:(DOMRange *)proposedRange affinity:(NSSelectionAffinity)selectionAffinity stillSelecting:(BOOL)flag
{
    return NO; // Prevent the selection of content.
}

#pragma mark - Interface Builder Actions

- (IBAction)showProfile:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:self.profileURL];
}

@end
