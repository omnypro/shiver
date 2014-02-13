//
//  ApplicationController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <EXTScope.h>

#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "Preferences.h"
#import "Reachability.h"
#import "StartAtLoginController.h"
#import "StatusItemView.h"
#import "WindowController.h"

#import "ApplicationController.h"

@interface ApplicationController ()
@property (nonatomic, strong) StartAtLoginController *loginController;
@property (nonatomic, readwrite, strong) WindowController *windowController;
@property (nonatomic, strong) Preferences *preferences;
@property (strong, nonatomic) RACReplaySubject *reachSignal;
@property (nonatomic, strong) Reachability *reach;
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
    NSImage *image = [NSImage imageNamed:@"StatusItem"];
    NSImage *alternateImage = [NSImage imageNamed:@"StatusItemAlternate"];
    NSWindow *window = self.windowController.window;
    self.statusItem = [[StatusItemView alloc] initWithWindow:window image:image alternateImage:alternateImage label:nil];
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[Preferences sharedPreferences] setupDefaults];

    // Preload the window.
    (void)self.windowController.window;

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
