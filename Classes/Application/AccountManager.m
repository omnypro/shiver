//
//  AccountManager.m
//  Shiver
//
//  Created by Bryan Veloso on 2/11/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <EXTKeypathCoding.h>
#import <EXTScope.h>

#import "Reachability.h"
#import "TwitchAPIClient.h"

#import "AccountManager.h"

@implementation AccountManager

+ (AccountManager *)sharedManager
{
    static AccountManager *_sharedManager = nil;
    if (_sharedManager == nil) {
        _sharedManager = [[super alloc] init];

        [[Reachability reachabilityWithHostname:@"twitch.tv"] startNotifier];
    }

    return _sharedManager;
}

- (RACSignal *)reachableSignal
{
    RACMulticastConnection *_isReachable;
    if (_isReachable == nil) {
        _isReachable = [[[[[NSNotificationCenter defaultCenter] rac_addObserverForName:kReachabilityChangedNotification object:nil] takeUntil:[self rac_willDeallocSignal]] map:^id(NSNotification *notification) {
            if ([[notification object] isReachable]) {
                DDLogInfo(@"Application (%@): %@", [self class], @"We have internets.");
                return @(YES);
            } else {
                DDLogInfo(@"Application (%@): %@", [self class], @"We don't have internets.");
                return @(NO);
            }
        }] multicast:[RACReplaySubject replaySubjectWithCapacity:1]];
        [_isReachable connect];
    }

    return _isReachable.signal;
}

@end
