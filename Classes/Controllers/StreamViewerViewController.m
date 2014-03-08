//
//  StreamViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 2/14/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import <WebKit/WebKit.h>

#import "EmptyViewerView.h"
#import "HexColor.h"
#import "MainWindowController.h"
#import "Preferences.h"
#import "SORelativeDateTransformer.h"
#import "StreamViewerView.h"
#import "StreamViewModel.h"
#import "TitleView.h"
#import "TwitchAPIClient.h"
#import "UserImageView.h"
#import "UserViewModel.h"

#import "StreamViewerViewController.h"

@interface StreamViewerViewController ()

@property (nonatomic, strong) TwitchAPIClient *client;
@property (nonatomic, strong) Preferences *preferences;
@property (nonatomic, strong) MainWindowController *windowController;

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSURL *chatURL;
@property (nonatomic, strong) NSURL *profileURL;
@property (nonatomic, strong) TitleView *titleView;
@property (nonatomic, strong) UserViewModel *userViewModel;
@property (nonatomic, strong) WebScriptObject *wso;

@property (nonatomic, assign) float videoVolume;

@property (weak) IBOutlet StreamViewerView *viewerView;

@end

@implementation StreamViewerViewController

- (id)initWithViewModel:(RVMViewModel *)viewModel nibName:(NSString *)nibName bundle:(NSBundle *)bundle
{
    self = [super initWithViewModel:viewModel nibName:nibName bundle:bundle];
    if (self == nil) { return nil; }

    _client = [TwitchAPIClient sharedClient];
    _preferences = [Preferences sharedPreferences];
    _windowController = [[NSApp delegate] windowController];

    _titleView = [_windowController titleView];
    _userViewModel = [[UserViewModel alloc] init];

    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

    NSWindow *window = self.windowController.window;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignKey:) name:NSWindowDidResignKeyNotification object:window];

    self.wso = [self.webView windowScriptObject];

    @weakify(self);

    RACSignal *hasStream = [RACObserve(self, stream)
        map:^id(id value) {
            return @(value != nil);
        }];

    // Observe the stream. If its value is set to nil, deactivate the viewer
    // interface (setting the titleView to inactive, etc).
    [[[[RACObserve(self, stream) distinctUntilChanged]
        filter:^BOOL(id value) {
            return (value == nil); }]
        deliverOn:[RACScheduler mainThreadScheduler]]
        subscribeNext:^(id x) {
            @strongify(self);
            DDLogInfo(@"Stream has been cleared. Deactivate the viewer.");
            [[self.webView mainFrame] loadHTMLString:nil baseURL:nil];
            [self.titleView setIsActive:NO];
            if ([self.viewerView superview] != nil) {
                [self.viewerView removeFromSuperview];
            }
        }];

    // Observe the stream, ignoring nil values. If its value is set, activate
    // the viewer interface (setting the title view to active, etc).
    [[[RACObserve(self, stream) ignore:nil]
        deliverOn:[RACScheduler mainThreadScheduler]]
        subscribeNext:^(id x) {
            @strongify(self);
            if ([self.viewerView superview] == nil) {
                DDLogInfo(@"We have a stream. Activate the viewer.");
                [self.titleView setIsActive:YES];
                [self.viewerView setFrame:self.view.bounds];
                [self.view addSubview:self.viewerView];
            }
        }];

    // Every 60 seconds, fetch the current stream from the API, refreshing it.
    [[[RACSignal
        interval:60
        onScheduler:[RACScheduler scheduler]]
        flattenMap:^RACStream *(id value) {
            @strongify(self);
            return [self.client fetchStream:self.stream.name]; }]
        subscribeNext:^(StreamViewModel *stream) {
            @strongify(self);
            DDLogInfo(@"Refreshing %@.", stream.name);
            self.stream = stream;
        }];

    // Compare the current stream to the recently set stream, if they're not
    // the same, load that stream into the web view. If they are (which is the
    // case during refreshing), don't do anything.
    [[RACObserve(self, stream)
        combinePreviousWithStart:nil
        reduce:^id(id previous, id current) {
            DDLogVerbose(@"Previous stream = [%@], Current stream = [%@]", previous, current);
            return RACTuplePack(previous, current); }]
        subscribeNext:^(RACTuple *tuple) {
            @strongify(self);
            RACTupleUnpack(StreamViewModel *previous, StreamViewModel *current) = tuple;
            if (![previous.name isEqualToString:current.name]) {
                NSURLRequest *request = [NSURLRequest requestWithURL:current.hlsURL];
                [[self.webView mainFrame] loadRequest:request];
            }
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

    RAC(self, viewerView.liveSinceLabel.stringValue, @"") = [RACObserve(self, stream.updatedAt)
        map:^id(NSDate *value) {
            if (value) { return [NSString stringWithFormat:@"Went live %@", [self relativeDateWithTimestamp:value]]; }
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
    [self.titleView.closeButton rac_liftSelector:@selector(setHidden:) withSignals:[hasStream not], nil];
    [self.titleView.closeButton setAction:@selector(closeStream:)];
    [self.titleView.closeButton setTarget:self];

    RAC(self, profileURL) = [RACObserve(self, stream.name)
        map:^id(NSString *name) {
            return [NSURL URLWithString:[NSString stringWithFormat:@"http://twitch.tv/%@/profile", name]];
        }];

    // Here's a hacky check to see if we should enable the follow button.
    // If we have a user's name, enable the button.
    // RACSignal *enableFollowButton = [[RACObserve(self, userViewModel.name)
    //     map:^id(id value) {
    //         return @(value != nil);
    //     }] deliverOn:[RACScheduler mainThreadScheduler]];
    // [self.viewerView.followButton rac_liftSelector:@selector(setEnabled:) withSignals:enableFollowButton, nil];
    [self.viewerView.followButton setEnabled:NO];

    // Set the text for the follow button. Run -isUserFollowingChannel: and
    // process the results.
    RAC(self, viewerView.followButton.title, @"Connect to Follow") = [[[[RACObserve(self, stream) ignore:nil]
        flattenMap:^RACStream *(StreamViewModel *stream) {
            return [self.userViewModel isUserFollowingChannel:stream.name]; }]
        map:^id(id responseObject) {
            return [responseObject boolValue] ? @"Following" : @"Follow";
        }] deliverOn:[RACScheduler mainThreadScheduler]];

    [_webView setFrameLoadDelegate:self];
    [_webView setMaintainsBackForwardList:NO];
}

- (NSString *)relativeDateWithTimestamp:(NSDate *)timestamp
{
    SORelativeDateTransformer *relativeDateTransformer = [[SORelativeDateTransformer alloc] init];
    return [relativeDateTransformer transformedValue:timestamp];
}

- (void)setVolume
{
    NSSlider *slider = self.viewerView.volumeSlider;
    float value = (float)slider.integerValue * 0.01;
    [self.wso evaluateWebScript:[NSString stringWithFormat:@"video.volume = %f;", value]];
}

#pragma mark - WebFrameLoadDelegate Methods

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    // We manipulate the <video> element via Javascript to hide the native
    // controls so we can implement our own.
    [self.wso evaluateWebScript:[NSString stringWithFormat:@"video = document.getElementById('content_player')"]];
    [self.wso evaluateWebScript:[NSString stringWithFormat:@"video.removeAttribute('controls');"]];
    [self setVolume];
}

- (BOOL)webView:(WebView *)webView shouldChangeSelectedDOMRange:(DOMRange *)currentRange toDOMRange:(DOMRange *)proposedRange affinity:(NSSelectionAffinity)selectionAffinity stillSelecting:(BOOL)flag
{
    return NO; // Prevent the selection of content.
}

#pragma mark - NSNotifcationCenter

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    // We will always reset the volume when becoming key, whether or not the
    // background sound setting is set. This is to prevent perceived
    // inconsistency in the preference.
    [self setVolume];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    if (![self.preferences backgroundSoundEnabled]) {
        [self.wso evaluateWebScript:[NSString stringWithFormat:@"video.volume = 0;"]];
    } else {
        // Set volume when resigning and the background sound preference is
        // disabled, preventing the perception of inconsistency.
        [self setVolume];
    }
}

#pragma mark - Interface Builder Actions

- (IBAction)closeStream:(id)sender
{
    DDLogInfo(@"User has asked to close the active stream.");
    [self setStream:nil];
}

- (IBAction)changeVolume:(id)sender
{
    [self setVolume];
}

- (IBAction)reloadStream:(id)sender
{
    [self.webView reload:sender];
}

- (IBAction)showProfile:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:self.profileURL];
}

- (IBAction)showChat:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:self.chatURL];
}

- (IBAction)togglePlayPause:(id)sender
{
    NSUInteger state = [sender state];
    if (state) { [self.wso evaluateWebScript:@"video.pause()"]; }
    else { [self.wso evaluateWebScript:@"video.play()"]; }
}

@end
