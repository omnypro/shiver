//
//  StreamListViewModel.m
//  Shiver
//
//  Created by Bryan Veloso on 2/14/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "AccountManager.h"
#import "Stream.h"
#import "StreamViewModel.h"
#import "TwitchAPIClient.h"

#import "StreamListViewModel.h"

@interface StreamListViewModel ()

@property (nonatomic, strong) TwitchAPIClient *client;

@end

@implementation StreamListViewModel

- (instancetype)init
{
    self = [super init];
    if (self == nil) return nil;

    _client = [TwitchAPIClient sharedClient];

    [self initializeSignals];

    return self;
}

- (void)initializeSignals
{
    // A combined singal for whether or not the account manager is
    // both ready and reachable.
    RACSignal *readyAndReachable = [[AccountManager sharedManager] readyAndReachableSignal];

    // Signals related to credential checking.
    RACSignal *credentialSignal = RACObserve(AccountManager.sharedManager, credential);
    RACSignal *hasCredential = [credentialSignal map:^(AFOAuthCredential *credential) { return @(credential != nil); }];

    RACSignal *fetchAuthenticatedStreams = [[self.client fetchStreamList] deliverOn:[RACScheduler mainThreadScheduler]];
    [fetchAuthenticatedStreams subscribeError:^(NSError *error) { DDLogError(@"Application (%@): (Error) %@", [self class], error); }];
    RAC(self, authenticatedStreams) = [RACSignal
        combineLatest:@[readyAndReachable, hasCredential, fetchAuthenticatedStreams]
        reduce:^id(NSNumber *readyAndReachable, NSNumber *hasCredential, NSArray *streams){
            DDLogInfo(@"Application (%@): Fetching authenticated stream list.", [self class]);
            if ([readyAndReachable boolValue] && [hasCredential boolValue] && streams != nil) {
                DDLogInfo(@"Application (%@): %lu streams fetched.", [self class], [streams count]);
                return streams;
            } else {
                return nil;
            }
        }
    ];

    RACSignal *fetchFeaturedStreams = [[self.client fetchFeaturedStreamList] deliverOn:[RACScheduler mainThreadScheduler]];
    [fetchFeaturedStreams subscribeError:^(NSError *error) { DDLogError(@"Application (%@): (Error) %@", [self class], error); }];
    RAC(self, featuredStreams) = [RACSignal
        combineLatest:@[readyAndReachable, hasCredential, fetchFeaturedStreams]
        reduce:^id(NSNumber *readyAndReachable, NSNumber *hasCredential, NSArray *streams){
            DDLogInfo(@"Application (%@): Fetching featured stream list.", [self class]);
            if ([readyAndReachable boolValue] && [hasCredential boolValue] && streams != nil) {
                DDLogInfo(@"Application (%@): %lu streams fetched.", [self class], [streams count]);
                return streams;
            } else {
                return nil;
            }
        }
    ];
}

@end
