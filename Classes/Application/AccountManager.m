//
//  AccountManager.m
//  Shiver
//
//  Created by Bryan Veloso on 2/11/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "Reachability.h"
#import "TwitchAPIClient.h"

#import "AccountManager.h"

@interface AccountManager ()

@property (nonatomic, strong) TwitchAPIClient *apiClient;

@end

@implementation AccountManager

+ (AccountManager *)sharedManager
{
    static AccountManager *_sharedManager = nil;
    if (_sharedManager == nil) {
        _sharedManager = [[super alloc] init];

        // Start the reachability notifier to make sure we have internets.
        [[Reachability reachabilityWithHostname:@"twitch.tv"] startNotifier];
    }

    return _sharedManager;
}

- (id)init
{
    self = [super init];
    if (self == nil) { return nil; }

    // Observe the API client's credential value and change ours if
    // that value changes.
    _apiClient = [TwitchAPIClient sharedClient];
    RAC(self, credential) = RACObserve(self, apiClient.credential);

    return self;
}

#pragma mark - Status Signals

- (RACSignal *)readySignal
{
    RACMulticastConnection *_isReady;
    if (_isReady == nil) {
        _isReady = [[RACObserve(self, credential) map:^id(AFOAuthCredential *credential) {
            DDLogInfo(@"%@", credential != nil ? @"We have a credential." : @"We don't have a credential.");
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
                DDLogInfo(@"%@", @"We have internets.");
                return @(YES);
            } else {
                DDLogInfo(@"%@", @"We don't have internets.");
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
