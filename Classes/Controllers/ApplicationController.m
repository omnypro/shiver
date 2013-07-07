//
//  ApplicationController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "Preferences.h"
#import "StartAtLoginController.h"
#import "StatusItemView.h"
#import "WindowController.h"

#import "ApplicationController.h"

@interface ApplicationController ()
@property (nonatomic, strong) StartAtLoginController *loginController;
@property (nonatomic, readwrite, strong) WindowController *windowController;
@property (nonatomic, strong) Preferences *preferences;
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

    _preferences = [Preferences sharedPreferences];
    _loginController = [[StartAtLoginController alloc] initWithIdentifier:ShiverHelperIdentifier];
    _windowController = [[WindowController alloc] init];
    return self;
}

- (void)awakeFromNib
{
    [[Preferences sharedPreferences] setupDefaults];

    NSImage *image = [NSImage imageNamed:@"StatusItem"];
    NSImage *alternateImage = [NSImage imageNamed:@"StatusItemAlternate"];
    NSWindow *window = self.windowController.window;
    self.statusItem = [[StatusItemView alloc] initWithWindow:window image:image alternateImage:alternateImage label:nil];
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Preload the window.
    (void)self.windowController.window;

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"ShiverAutoStart"]) {
        [self.loginController setStartAtLogin:YES];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ShiverAutoStart"];
    }

    [self initializeLogging];
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

@end
