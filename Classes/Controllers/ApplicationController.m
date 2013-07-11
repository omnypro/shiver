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
    [self initializeReachability];
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

- (void)initializeReachability
{
    @weakify(self);

    self.reachSignal = [RACReplaySubject subject];

    self.reach = [Reachability reachabilityForInternetConnection];
    [self.reach setUnreachableBlock:^(Reachability* reach) {
        @strongify(self);
        [self.reachSignal sendNext:reach];
    }];
    [self.reach setReachableBlock:^(Reachability *reach){
        @strongify(self);
        [self.reachSignal sendNext:reach];
    }];

    [self.reachSignal subscribeNext:^(Reachability *reach) {
        @strongify(self);

        // Send a signal off to our WindowController's -reachSignal
        // to update the UI, etc.
        DDLogInfo(@"Application (%@): %@", [self class], reach.isReachable ? @"We have internets." : @"We don't have internets.");
        [self.windowController.reachSignal sendNext:reach];
    }];

    [self.reachSignal sendNext:self.reach];
    [self.reach startNotifier];
}

@end
