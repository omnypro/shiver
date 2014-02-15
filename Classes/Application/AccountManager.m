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

        // Let'se see if a credential is already stored in the user's keychain.
        AFOAuthCredential *credential = [[NSUserDefaults standardUserDefaults] objectForKey:@"accessToken"];
        if (credential != nil) { _sharedManager.credential = credential; }
    }

    return _sharedManager;
}

#pragma mark - Status Signals

- (RACSignal *)readySignal
{
    RACMulticastConnection *_isReady;
    if (_isReady == nil) {
        _isReady = [[RACObserve(self, credential) map:^id(AFOAuthCredential *credential) {
            DDLogInfo(@"Application (%@): %@", [self class], credential != nil ? @"We have a credential." : @"We don't have a credential.");
            return @(credential != nil);
        }] multicast:[RACReplaySubject replaySubjectWithCapacity:1]];
        [_isReady connect];
    }
    return _isReady.signal;
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

- (RACSignal *)readyAndReachableSignal
{
    return [[[RACSignal combineLatest:@[self.readySignal, self.reachableSignal]] and] distinctUntilChanged];
}

@end
