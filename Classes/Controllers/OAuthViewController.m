//
//  OAuthViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/9/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "OAuthViewController.h"

#import "APIClient.h"
#import "User.h"

@interface OAuthViewController () {
    IBOutlet NSButton *_loginButton;
    IBOutlet NSButton *_learnMoreButton;
    IBOutlet NSTextField *_connectionStatusLabel;

    IBOutlet NSWindow *_modalWindow;
    IBOutlet WebView *_modalWebView;
    IBOutlet NSProgressIndicator *_progressIndicator;
}

- (IBAction)loginOrLogout:(NSButton *)sender;
- (IBAction)learnMore:(NSButton *)sender;
@end

@implementation OAuthViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)awakeFromNib
{
    [_modalWebView setFrameLoadDelegate:self];
    if ([[APIClient sharedClient] isAuthenticated]) {
        [User userWithBlock:^(User *user, NSError *error) {
            if (user) { [_connectionStatusLabel setStringValue:[NSString stringWithFormat:@"You're logged in as %@.", user.name]]; }
        }];
        [_loginButton setTitle:@"Disconnect Twitch"];
    }

    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getURL:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

#pragma mark - Sheet Lifecycle Methods

- (void)getURL:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSLog(@"urlString: %@", urlString);

    NSURL *url = [NSURL URLWithString:urlString];
    [NSApp endSheet:_modalWindow];
    [self didEndSheet:_modalWindow returnCode:0 contextInfo:nil];

    if ([url query] != nil && [[url query] rangeOfString:@"access_denied"].location != NSNotFound) {
        // Make the user feel bad. DO NOT DENY ME! D:
        [_connectionStatusLabel setTextColor:[NSColor redColor]];
        [_connectionStatusLabel setStringValue:@"You refused to grant access. :("];
    }
    if ([url fragment] != nil && [[url fragment] rangeOfString:@"access_token"].location != NSNotFound) {
        // Authenticate and update the interface.
        [[APIClient sharedClient] authorizeUsingResponseURL:url];
        [User userWithBlock:^(User *user, NSError *error) {
            [_connectionStatusLabel setStringValue:[NSString stringWithFormat:@"You're logged in as %@.", user.name]];
            [_loginButton setTitle:@"Disconnect Twitch"];
            [[NSNotificationCenter defaultCenter] postNotificationName:UserDidConnectAccountNotification object:self userInfo:nil];
        }];
    }
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

#pragma mark - RHPreferencesViewControllerProtocol

- (NSString*)identifier
{
    return NSStringFromClass(self.class);
}

- (NSImage*)toolbarItemImage
{
    return [NSImage imageNamed:@"PreferencesGlitch"];
}

-(NSString*)toolbarItemLabel
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

- (IBAction)loginOrLogout:(NSButton *)sender
{
    if ([[APIClient sharedClient] isAuthenticated]) {
        [[APIClient sharedClient] logout];

        // Update the interface.
        [_connectionStatusLabel setStringValue:@"Not currently connected."];
        [_loginButton setTitle:@"Connect With Twitch"];

        // Alert the residents!
        [[NSNotificationCenter defaultCenter] postNotificationName:UserDidDisconnectAccountNotification object:self userInfo:nil];
    } else {
        NSString *authorizationURL = [NSString stringWithFormat:@"%@oauth2/authorize/?client_id=%@&redirect_uri=%@&response_type=token&scope=user_read", kTwitchBaseURL, kClientID, kRedirectURI];
        [_modalWebView setMainFrameURL:authorizationURL];

        [[NSApplication sharedApplication] beginSheet:_modalWindow modalForWindow:self.view.window modalDelegate:self didEndSelector:nil contextInfo:nil];
    }
}

- (IBAction)learnMore:(NSButton *)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://twitch.tv"]];
}

@end
