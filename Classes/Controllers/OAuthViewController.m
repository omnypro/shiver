//
//  OAuthViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/9/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <EXTScope.h>

#import "TwitchAPIClient.h"
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

@property (nonatomic, strong) TwitchAPIClient *client;
@property (nonatomic, strong) AFOAuthCredential *credential;
@property (nonatomic, strong) User *user;

@property (nonatomic, assign) BOOL loggingIn;
@property (nonatomic, strong) RACCommand *disconnectCommand;
@property (nonatomic, strong) RACCommand *loginCommand;

@end

@implementation OAuthViewController

- (id)init
{
    self = [super initWithNibName:@"OAuthView" bundle:nil];
    if (self == nil) { return nil; }

    self.credential = [[NSUserDefaults standardUserDefaults] objectForKey:@"accessToken"];
    self.loginCommand = [RACCommand command];
    self.disconnectCommand = [RACCommand command];
    self.didLogoutSubject = [RACReplaySubject subject];
    self.didLoginSubject = [RACReplaySubject subject];

    [self setUpAuthenticationSignals];
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.loggingIn = NO;

    // Call the -sharedAppleEventManager and set an event handler to grab the
    // callbacks from Twitch's authentication system.
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleAppleEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];

    [self setUpViewSignals];

    [_modalWebView setFrameLoadDelegate:self];
}

- (void)setUpViewSignals
{
    @weakify(self);

    _loginButton.rac_command = self.loginCommand;
    [[self.loginCommand
      deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
        @strongify(self);
        NSLog(@"Authentication: Kicking off the login process.");
        self.client = [TwitchAPIClient sharedClient];
        self.loggingIn = YES;
    }];

    _disconnectButton.rac_command = self.disconnectCommand;
    [[self.disconnectCommand
      deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
        @strongify(self);
        NSLog(@"Authentication: Logging out and removing credentials.");
        self.client = [TwitchAPIClient sharedClient];
        self.credential = nil;
        self.user = nil;

        [self.client logout];
        [self.didLogoutSubject sendNext:RACTuplePack(self.credential, self.user)];
    }];

    // Watch to see if the value of user is set. If so, change the respective
    // UI elements to reflect the fact that we have a user present.
    [[RACAbleWithStart(self.credential) filter:^BOOL(id value) {
        return (value != nil);
    }] subscribeNext:^(id x) {
        @strongify(self);
        [_connectionStatusLabel setStringValue:@"You're logged in."];
        [_disconnectButton setHidden:NO];
        [_loginButton setHidden:YES];

        if (self.user) { [_connectionStatusLabel setStringValue:[NSString stringWithFormat:@"You're logged in as %@.", self.user.name]]; }
    }];

    // This time, we're watching to see if the value of user is `nil`. If so,
    // we'll revert all of the UI elements back to their original forms.
    [[RACAbleWithStart(self.credential) filter:^BOOL(id value) {
        return (value == nil);
    }] subscribeNext:^(id x) {
        [_connectionStatusLabel setStringValue:@"Not currently connected."];
        [_disconnectButton setHidden:YES];
        [_loginButton setHidden:NO];
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
        [[[RACSignal combineLatest:@[ [self.client authorizeUsingResponseURL:x], [self.client fetchUser] ] reduce:^(AFOAuthCredential *credential, User *user) {
            @strongify(self);
            NSLog(@"Authentication: (Credential) %@", credential.accessToken);
            NSLog(@"Authentication: (User) %@", user.name);
            self.credential = credential;
            self.user = user;
        }] deliverOn:[RACScheduler mainThreadScheduler]] subscribeCompleted:^{
            @strongify(self);
            NSLog(@"Authentication: Complete for %@.", self.user.name);
            [self.didLoginSubject sendNext:RACTuplePack(self.credential, self.user)];
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
