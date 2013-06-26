//
//  OAuthViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/9/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <EXTScope.h>

#import "APIClient.h"
#import "NSView+SHExtensions.h"
#import "OAuthView.h"
#import "User.h"

#import "OAuthViewController.h"

@interface OAuthViewController () {
    IBOutlet NSButton *_disconnectButton;
    IBOutlet NSButton *_loginButton;
    IBOutlet NSButton *_learnMoreButton;
    IBOutlet NSTextField *_connectionStatusLabel;

    IBOutlet NSWindow *_modalWindow;
    IBOutlet WebView *_modalWebView;
    IBOutlet NSProgressIndicator *_progressIndicator;
}

@property (nonatomic, strong) APIClient *client;
@property (nonatomic, strong) User *user;

@property (nonatomic, assign) BOOL loggingIn;
@property (nonatomic, strong) RACCommand *disconnectCommand;
@property (nonatomic, strong) RACCommand *loginCommand;
@property (nonatomic, strong, readwrite) RACSubject *didLoginSubject;
@property (nonatomic, strong, readwrite) RACSubject *URLProtocolValueSubject;

- (IBAction)learnMore:(NSButton *)sender;
@end

@implementation OAuthViewController

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.loggingIn = NO;
    self.loginCommand = [RACCommand command];
    self.didLoginSubject = [RACSubject subject];

    [self setUpViewSignals];
    [self setUpAuthenticationSignals];

    // Call the -sharedAppleEventManager and set an event handler to grab the
    // callbacks from Twitch's authentication system.
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleAppleEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];

    [_modalWebView setFrameLoadDelegate:self];
}

- (void)setUpViewSignals
{
    @weakify(self);

    // Watch to see if the value of user is set. If so, change the respective
    // UI elements to reflect the fact that we have a user present.
    [[[RACAbleWithStart(self.user) filter:^BOOL(id value) {
        return (value != nil);
    }] deliverOn:[RACScheduler scheduler]] subscribeNext:^(id x) {
        @strongify(self);
        [_connectionStatusLabel setStringValue:[NSString stringWithFormat:@"You're logged in as %@.", self.user.name]];
        [_disconnectButton setHidden:NO];
        [_loginButton setHidden:YES];

    }];

    // This time, we're watching to see if the value of user is `nil`. If so,
    // we'll revert all of the UI elements back to their original forms.
    [[[RACAbleWithStart(self.user) filter:^BOOL(id value) {
        return (value == nil);
    }] deliverOn:[RACScheduler scheduler]] subscribeNext:^(id x) {
        [_connectionStatusLabel setStringValue:@"Not currently connected."];
        [_disconnectButton setHidden:YES];
        [_loginButton setHidden:NO];
    }];

    _loginButton.rac_command = self.loginCommand;
    [self.loginCommand subscribeNext:^(id x) {
        @strongify(self);
        self.client = [APIClient sharedClient];
        self.loggingIn = YES;
    }];

    _disconnectButton.rac_command = self.disconnectCommand;
    [self.disconnectCommand subscribeNext:^(id x) {
        @strongify(self);
        self.client = [APIClient sharedClient];
        self.user = nil;
    }];
}

- (void)setUpAuthenticationSignals
{
    @weakify(self);

    // Spectate loggingIn. If true, open the modal and start the journey.
    [[RACAble(self.loggingIn) distinctUntilChanged] subscribeNext:^(NSNumber *loggingIn) {
        @strongify(self);
        BOOL isLoggingIn = [loggingIn boolValue];
        if (isLoggingIn) {
            NSString *authorizationURL = [NSString stringWithFormat:@"%@oauth2/authorize/?client_id=%@&redirect_uri=%@&response_type=token&scope=user_read", kTwitchBaseURL, kClientID, kRedirectURI];
            [self->_modalWebView setMainFrameURL:authorizationURL];
            [[NSApplication sharedApplication] beginSheet:_modalWindow modalForWindow:self.view.window modalDelegate:self didEndSelector:nil contextInfo:nil];
        }
    }];

    // Reusable throwaway function for closing sheets.
    void (^closeSheet)(void) = ^{
        [NSApp endSheet:_modalWindow];
        [_modalWindow orderOut:self];
    };

    // Contains the callback from Twitch.
    self.URLProtocolValueSubject = [RACSubject subject];

    // Filter the subject for a callback containing "access_denied". If so,
    // close the modal and alert the interface that we've been denied. :(
    // e.g. shiver://authorize?error=access_denied
    [[self.URLProtocolValueSubject filter:^BOOL(NSURL *url) {
        return ([url query] != nil && [[url query] rangeOfString:@"access_denied"].location != NSNotFound);
    }] subscribeNext:^(id x) {
        @strongify(self);
        NSLog(@"Authentication: We've been denied.");

        closeSheet();
        self.loggingIn = NO;
    }];

    // Filter the subject for a callback containing "access_token".
    // e.g. shiver://authorize#access_token=[access_token]&scope=user_read
    [[self.URLProtocolValueSubject filter:^BOOL(NSURL *url) {
        return ([url fragment] != nil && [[url fragment] rangeOfString:@"access_token"].location != NSNotFound);
    }] subscribeNext:^(id x) {
        @strongify(self);
        NSLog(@"Authentication: We've been granted access.");

        closeSheet();
        [[RACSignal combineLatest:@[ [self.client authorizeUsingResponseURL:x], [self.client fetchUser] ] reduce:^(AFOAuthCredential *credential, User *user) {
            @strongify(self);
            NSLog(@"Authentication: (Credential) %@", credential);
            NSLog(@"Authentication: (User) %@", user);
            self.user = user;
        }] subscribeCompleted:^{
            NSLog(@"Authentication: Complete for %@.", self.user);
            [self.didLoginSubject sendNext:self.user];
            self.loggingIn = NO;
        }];
    }];
}

#pragma mark - Sheet Lifecycle Methods

- (void)handleAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    // Despite this being a general URL string handler, we're only ever going to
    // track one type of event: callbacks from Twitch's authentication service.
    NSString *urlString = [event paramDescriptorForKeyword:keyDirectObject].stringValue;
    NSLog(@"Authentication: (URLString) %@", urlString);
    [self.URLProtocolValueSubject sendNext:[NSURL URLWithString:[urlString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

#pragma mark - RHPreferencesViewControllerProtocol

- (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"PreferencesGlitch"];
}

-(NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Twitch", @"OAuthToolbarItemLabel");
}

#pragma mark - WebFrameLoadDelgate Methods

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
    [_progressIndicator startAnimation:self];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    [_progressIndicator stopAnimation:self];
    [_progressIndicator setHidden:YES];
}

- (IBAction)learnMore:(NSButton *)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://twitch.tv"]];
}

@end
