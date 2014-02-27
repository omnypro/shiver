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
#import "YOLO.h"

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
    RACSignal *fetchFeaturedStreams = [[self.client fetchFeaturedStreamList] deliverOn:[RACScheduler mainThreadScheduler]];

    // ...
    RAC(self, isLoading, @YES) = [RACSignal
        combineLatest:@[RACObserve(self, authenticatedStreams), RACObserve(self, featuredStreams)]
        reduce:^id(NSArray *authenticatedStreams, NSArray *featuredStreams){
            return @(authenticatedStreams == nil || featuredStreams == nil);
        }];

    // ...
    RAC(self, authenticatedStreams) = [RACSignal
        combineLatest:@[readyAndReachable, hasCredential, fetchAuthenticatedStreams]
        reduce:^id(NSNumber *readyAndReachable, NSNumber *hasCredential, NSArray *streams){
            DDLogInfo(@"Application (%@): Fetching authenticated stream list.", [self class]);
            if ([readyAndReachable boolValue] && [hasCredential boolValue] && streams != nil) {
                DDLogInfo(@"Application (%@): %lu authenticated streams fetched.", [self class], [streams count]);
                return streams;
            } else {
                DDLogInfo(@"Application (%@): No authenticated streams fetched.", [self class]);
                return nil;
            }
        }
    ];
    [fetchAuthenticatedStreams
        subscribeError:^(NSError *error) {
            DDLogError(@"Application (%@): (Error) %@", [self class], error);
        }];

    // ...
    RAC(self, featuredStreams) = [RACSignal
        combineLatest:@[readyAndReachable, hasCredential, fetchFeaturedStreams, fetchAuthenticatedStreams]
        reduce:^id(NSNumber *readyAndReachable, NSNumber *hasCredential, NSArray *featuredStreams, NSArray *authenticatedStreams){
            DDLogInfo(@"Application (%@): Fetching featured stream list.", [self class]);
            if ([readyAndReachable boolValue] && [hasCredential boolValue] && featuredStreams != nil) {
                NSArray *streams = featuredStreams;
                if (authenticatedStreams != nil) {
                    // If authenticated streams are a thing, its contents from
                    // the featured stream list.
                    streams = streams.without(authenticatedStreams);
                } else {
                    streams = featuredStreams;
                }

                DDLogInfo(@"Application (%@): %lu streams fetched.", [self class], [featuredStreams count]);
                return streams.sortBy(@"name");
            } else {
                DDLogInfo(@"Application (%@): No featured streams fetched.", [self class]);
                return nil;
            }
        }
    ];
    [fetchFeaturedStreams
        subscribeError:^(NSError *error) {
            DDLogError(@"Application (%@): (Error) %@", [self class], error);
        }];

    // ...
    RAC(self, numberOfSections) = [RACSignal
        combineLatest:@[RACObserve(self, authenticatedStreams), RACObserve(self, featuredStreams)]
        reduce:^id(NSArray *authenticatedStreams, NSArray *featuredStreams){
            if (featuredStreams != nil) { return [NSNumber numberWithInt:2]; }
            else { return [NSNumber numberWithInt:1]; }
        }];
}

@end
