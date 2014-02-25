//
//  ApplicationController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <EXTScope.h>

#import "AboutWindowController.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "GeneralViewController.h"
#import "LoginViewController.h"
#import "MainWindowController.h"
#import "Preferences.h"
#import "Reachability.h"
#import "StartAtLoginController.h"
#import "StatusItemView.h"
#import "WindowController.h"
#import "WindowViewModel.h"

#import "ApplicationController.h"

@interface ApplicationController ()

@property (nonatomic, strong) WindowViewModel *viewModel;
@property (nonatomic, strong) MainWindowController *windowController;

@property (nonatomic, strong) AboutWindowController *aboutWindowController;
@property (nonatomic, strong) StartAtLoginController *loginController;

// Preferences.
@property (nonatomic, strong) Preferences *preferences;
@property (nonatomic, strong) RHPreferencesWindowController *preferencesWindowController;
@property (nonatomic, strong) GeneralViewController *generalPreferences;
@property (nonatomic, strong) LoginViewController *loginPreferences;

- (IBAction)showAbout:(id)sender;
- (IBAction)showPreferences:(id)sender;
- (IBAction)showMainWindow:(id)sender;

@end

@implementation ApplicationController

+ (ApplicationController *)sharedInstance
{
    return [NSApp delegate];
}

- (id)init
{
	self = [super init];
	if (self == nil) { return nil; }

    _viewModel = [[WindowViewModel alloc] init];
    _windowController = [[MainWindowController alloc] initWithViewModel:_viewModel nibName:@"MainWindow"];

    _loginController = [[StartAtLoginController alloc] initWithIdentifier:ShiverHelperIdentifier];

    _aboutWindowController = [[AboutWindowController alloc] init];

    _preferences = [Preferences sharedPreferences];
    _generalPreferences = [[GeneralViewController alloc] init];
    _loginPreferences = [[LoginViewController alloc] init];

    return self;
}

- (void)awakeFromNib
{
    [self initializeStatusItem];
}

#pragma mark - Preferences

- (NSWindowController *)preferencesWindowController
{
    // If we have not created the window controller yet, create it now.
    if (_preferencesWindowController == nil) {
        NSArray *controllers = @[ self.generalPreferences, self.loginPreferences ];
        _preferencesWindowController = [[RHPreferencesWindowController alloc] initWithViewControllers:controllers andTitle:NSLocalizedString(@"Shiver Preferences", @"Preferences Window Title")];
    }
    return _preferencesWindowController;
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[Preferences sharedPreferences] setupDefaults];

    // Preload the window.
    (void)self.windowController.window;
    [self.windowController showWindow:self];

    [self initializeLogging];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    if (flag == NO) { [self.windowController.window makeKeyAndOrderFront:self]; }
    return YES;
}

- (void)initializeLogging
{
    // We log too verbosely for the console in development. Let's only add it
    // when running a release build.
#ifndef DEBUG
    [DDLog addLogger:[DDASLLogger sharedInstance]];
#endif
    [DDLog addLogger:[DDTTYLogger sharedInstance]];

    NSString *productName =  [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    NSString *shortVersionString = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    DDLogInfo(@"Application: Loaded %@ v%@", productName, shortVersionString);
}

- (void)initializeStatusItem
{
    NSImage *image = [NSImage imageNamed:@"StatusItem"];
    NSImage *alternateImage = [NSImage imageNamed:@"StatusItemAlternate"];
    NSStatusBar *bar = [NSStatusBar systemStatusBar];

    self.statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setImage:image];
    [self.statusItem setAlternateImage:alternateImage];
    [self.statusItem setHighlightMode:YES];
    [self.statusItem setAction:@selector(toggleWindow)];
}

- (void)toggleWindow
{
    NSWindow *window = self.windowController.window;
    if ([window isKeyWindow]) { [window orderOut:self]; }
    else { [window makeKeyAndOrderFront:self]; }
}

#pragma mark - Interface Builder Actions

- (IBAction)showAbout:(id)sender {
    [self.aboutWindowController.window center];
    [self.aboutWindowController.window makeKeyAndOrderFront:sender];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)showPreferences:(id)sender
{
    [self.preferencesWindowController.window center];
    [self.preferencesWindowController.window makeKeyAndOrderFront:sender];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)showMainWindow:(id)sender {
    [self.windowController.window makeKeyAndOrderFront:sender];
}

@end
