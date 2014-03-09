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
    _hasError = NO;

    [self initializeSignals];

    return self;
}

- (void)initializeSignals
{
    self.refreshCommand = [[RACCommand alloc]
        initWithSignalBlock:^RACSignal *(id input) {
            return [RACSignal return:@1];
        }];

    // A combined signal for whether or not the account manager is
    // both ready and reachable. Also: signal related to credential checking.
    RACSignal *reachableSignal = [[AccountManager sharedManager] reachableSignal];
    RACSignal *readyAndReachable = [[AccountManager sharedManager] readyAndReachableSignal];

    // Observes -readyAndReachable and our refresh action and returns whenever
    // either of those signals returns a value.
    RACSignal *executionSignal = [RACSignal merge:@[reachableSignal, [self.refreshCommand.executionSignals flatten]]];

    // ...
    RAC(self, isLoading, @YES) = [RACSignal
        combineLatest:@[reachableSignal, RACObserve(self, featuredStreams)]
        reduce:^id(NSNumber *reachable, NSArray *streams) {
            return @([reachable boolValue] && streams == nil);
        }];

    RAC(self, hasError) = [reachableSignal not];
    RAC(self, errorMessage) = [RACSignal return:@"We're lacking Internets."];

    // ...
    [RACObserve(self, featuredStreams)
        subscribeNext:^(id x) {
            DDLogDebug(@"self.featuredStreams: %@", x);
        }];

    // ...
    [RACObserve(self, authenticatedStreams)
        subscribeNext:^(id x) {
            DDLogDebug(@"self.authenticatedStreams: %@", x);
        }];

    // ...
    [[[[RACSignal
        combineLatest:@[readyAndReachable, executionSignal]]
        map:^id(id value) {
            return [RACSignal merge:@[[self updateAuthenticatedStreams], [self updateFeaturedStreams]]]; }] switchToLatest]
        subscribeError:^(NSError *error) {
            self.hasError = YES;
            self.errorMessage = [error localizedDescription];
            DDLogError(@"%@", self.errorMessage);
        }];
}

- (RACSignal *)updateAuthenticatedStreams
{
    DDLogInfo(@"Updating authenticated stream list.");
    return [[self.client fetchAuthenticatedStreamList]
        doNext:^(NSArray *streams) {
            self.authenticatedStreams = streams.sortBy(@"name");
            DDLogInfo(@"%lu authenticated streams fetched.", [streams count]);
        }];
}

- (RACSignal *)updateFeaturedStreams
{
    DDLogInfo(@"Fetching featured stream list.");
    return [[RACSignal
        combineLatest:@[[self.client fetchFeaturedStreamList], [self.client fetchAuthenticatedStreamList]]
        reduce:^id(NSArray *featured, NSArray *authenticated) {
            return [[featured.rac_sequence map:^id(StreamViewModel *stream) {
                if ([authenticated containsObject:stream]) { [stream setIsFollowed:YES]; }
                return stream;
            }] array]; }]
        doNext:^(NSArray *streams) {
            self.featuredStreams = streams.sortBy(@"name");
            DDLogInfo(@"%lu featured streams fetched.", [streams count]);
        }];
}

@end
