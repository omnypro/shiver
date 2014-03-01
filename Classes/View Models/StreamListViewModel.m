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
    // ...
    RAC(self, isLoading, @YES) = [RACSignal
        combineLatest:@[RACObserve(self, authenticatedStreams), RACObserve(self, featuredStreams)]
        reduce:^id(NSArray *authenticatedStreams, NSArray *featuredStreams){
            return @(authenticatedStreams == nil || featuredStreams == nil);
        }];

    // A combined singal for whether or not the account manager is
    // both ready and reachable. Also: signal related to credential checking.
    RACSignal *readyAndReachable = [[AccountManager sharedManager] readyAndReachableSignal];
    RACSignal *hasCredential = [RACObserve(AccountManager.sharedManager, credential) map:^(AFOAuthCredential *credential) { return @(credential != nil); }];

    RACSignal *fetchAuthenticatedStreams = [[self.client fetchStreamList] deliverOn:[RACScheduler mainThreadScheduler]];
    RACSignal *fetchFeaturedStreams = [[self.client fetchFeaturedStreamList] deliverOn:[RACScheduler mainThreadScheduler]];

    self.refreshCommand = [[RACCommand alloc]
        initWithSignalBlock:^RACSignal *(id input) {
            return [RACSignal return:@1];
        }];

    // ...
    RACSignal *executionSignal = [RACSignal merge:@[readyAndReachable, hasCredential, [self.refreshCommand.executionSignals flatten]]];

    // ...
    RAC(self, authenticatedStreams) = [RACSignal
        combineLatest:@[executionSignal, fetchAuthenticatedStreams]
        reduce:^id(NSNumber *executable, NSArray *streams) {
            DDLogInfo(@"Application (%@): Fetching authenticated stream list.", [self class]);
            if ([executable boolValue] && streams != nil) {
                DDLogInfo(@"Application (%@): %lu authenticated streams fetched.", [self class], [streams count]);
                return streams.sortBy(@"name");
            } else {
                DDLogInfo(@"Application (%@): No authenticated streams fetched.", [self class]);
                return nil;
            }
        }];
    [fetchAuthenticatedStreams
        subscribeError:^(NSError *error) {
            DDLogError(@"Application (%@): (Error) %@", [self class], error);
        }];

    // ...
    RAC(self, featuredStreams) = [RACSignal
        combineLatest:@[executionSignal, fetchFeaturedStreams, fetchAuthenticatedStreams]
        reduce:^id(NSNumber *executable, NSArray *featuredStreams, NSArray *authenticatedStreams){
            DDLogInfo(@"Application (%@): Fetching featured stream list.", [self class]);
            if ([executable boolValue] && featuredStreams != nil) {
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
        }];
    [fetchFeaturedStreams
        subscribeError:^(NSError *error) {
            DDLogError(@"Application (%@): (Error) %@", [self class], error);
        }];
}

@end
