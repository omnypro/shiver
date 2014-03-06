//
//  LoginViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/9/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "AccountManager.h"
#import "LoginView.h"
#import "NSView+SHExtensions.h"
#import "TwitchAPIClient.h"
#import "User.h"
#import "UserViewModel.h"

#import "LoginViewController.h"

@interface LoginViewController () {
    IBOutlet NSButton *_disconnectButton;
    IBOutlet NSButton *_loginButton;
    IBOutlet NSButton *_learnMoreButton;

    IBOutlet NSWindow *_modalWindow;
    IBOutlet WebView *_modalWebView;
    IBOutlet NSProgressIndicator *_progressIndicator;
}

@property (nonatomic, strong) TwitchAPIClient *client;
@property (nonatomic, strong) UserViewModel *userViewModel;

@property (nonatomic, assign) BOOL loggingIn;
@property (nonatomic, strong) RACCommand *disconnectCommand;
@property (nonatomic, strong) RACCommand *loginCommand;

@property (weak) IBOutlet NSTextField *connectionStatusLabel;

@end

@implementation LoginViewController

- (id)init
{
    self = [super initWithNibName:@"LoginView" bundle:nil];
    if (self == nil) { return nil; }

    _client = [TwitchAPIClient sharedClient];
    _didLogoutSubject = [RACReplaySubject subject];
    _didLoginSubject = [RACReplaySubject subject];
    _userViewModel = [[UserViewModel alloc] init];

    [self initializeAuthenticationSignals];
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    // Call the -sharedAppleEventManager and set an event handler to grab the
    // callbacks from Twitch's authentication system.
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleAppleEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];

    [self initializeViewSignals];
    [_modalWebView setFrameLoadDelegate:self];
}

- (void)initializeViewSignals
{
    @weakify(self);

    _loginButton.rac_command = [[RACCommand alloc]
        initWithSignalBlock:^RACSignal *(id input) {
            @strongify(self);
            DDLogInfo(@"Authentication: Kicking off the login process.");
            NSURLRequest *request = [NSURLRequest requestWithURL:[self.client authorizationURL]];
            [[_modalWebView mainFrame] loadRequest:request];
            [[NSApplication sharedApplication] beginSheet:_modalWindow modalForWindow:self.view.window modalDelegate:self didEndSelector:nil contextInfo:nil];
            return [RACSignal return:request];
        }];

    _disconnectButton.rac_command = [[RACCommand alloc]
        initWithSignalBlock:^RACSignal *(id input) {
            @strongify(self);
            DDLogInfo(@"Authentication: Logging out and removing credentials.");
            [self.client logout];
            return [RACSignal empty];
        }];

    RACSignal *isLoggedIn = RACObserve(self, userViewModel.isLoggedIn);

    // Watch to see if the value of user is set. If so, change the respective
    // UI elements to reflect the fact that we have a user present (or not).
    [_disconnectButton rac_liftSelector:@selector(setHidden:) withSignals:[isLoggedIn not], nil];
    [_loginButton rac_liftSelector:@selector(setHidden:) withSignals:isLoggedIn, nil];
    RAC(self, connectionStatusLabel.stringValue) = [isLoggedIn
        map:^id(id value) {
            return [value boolValue] ? @"You're logged in." : @"Not currently connected.";
        }];
}

- (void)initializeAuthenticationSignals
{
    @weakify(self);

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
        DDLogInfo(@"Authentication: We've been denied.");
        closeSheet();
    }];

    // Filter the subject for a callback containing "access_token".
    // e.g. shiver://authorize#access_token=[access_token]&scope=user_read
    [[self.URLProtocolValueSubject filter:^BOOL(NSURL *url) {
        return ([url fragment] != nil && [[url fragment] rangeOfString:@"access_token"].location != NSNotFound);
    }] subscribeNext:^(id x) {
        @strongify(self);
        DDLogInfo(@"Authentication: We've been granted access.");

        closeSheet();
        [[[self.client authorizeUsingResponseURL:x] deliverOn:[RACScheduler mainThreadScheduler]]
            subscribeNext:^(AFOAuthCredential *credential) {
                DDLogVerbose(@"Authentication: (Credential) %@", credential.accessToken);
            } error:^(NSError *error) {
                DDLogError(@"Authentication: %@", error);
            }];
    }];
}

#pragma mark - Sheet Lifecycle Methods

- (void)handleAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    // Despite this being a general URL string handler, we're only ever going to
    // track one type of event: callbacks from Twitch's authentication service.
    NSString *urlString = [event paramDescriptorForKeyword:keyDirectObject].stringValue;
    DDLogVerbose(@"Authentication: (URLString) %@", urlString);
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
