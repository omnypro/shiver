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

    // A signal whose result contains an array of featured stream items.
    RACSignal *featuredStreams = [[reachableSignal
        filter:^BOOL(id value) {
            return ([value boolValue] == YES); }]
        flattenMap:^RACStream *(id value) {
            return [[self.client fetchFeaturedStreamList] deliverOn:[RACScheduler mainThreadScheduler]];
        }];

    // A signal whose result either contains an array of authenticated stream
    // items, or an empty array. We squelch errors delivered by this method, so
    // we can still use it against RAC(self, featuredStreams).
    RACSignal *catchableAuthenticatedStreams = [readyAndReachable
        flattenMap:^RACStream *(id value) {
            return [[[self.client fetchAuthenticatedStreamList] deliverOn:[RACScheduler mainThreadScheduler]] catchTo:[RACSignal return:@[]]];
        }];

    // ...
    RAC(self, featuredStreams) = [[RACSignal
        combineLatest:@[executionSignal, featuredStreams, catchableAuthenticatedStreams]
        reduce:^id(NSNumber *executable, NSArray *featuredStreams, NSArray *authenticatedStreams){
            DDLogInfo(@"Fetching featured stream list.");
            if ([executable boolValue] && featuredStreams != nil) {
                // If authenticated streams are a thing, its contents from
                // the featured stream list.
                DDLogInfo(@"%lu streams fetched.", [featuredStreams count]);
                return [[featuredStreams.sortBy(@"name").rac_sequence
                    map:^id(StreamViewModel *stream) {
                        if ([authenticatedStreams containsObject:stream]) { [stream setIsFollowed:YES]; }
                        return stream;
                    }] array];
            } else {
                DDLogInfo(@"No featured streams fetched.");
                return @[];
            } }]
        catch:^RACSignal *(NSError *error) {
            self.hasError = YES;
            self.errorMessage = [error localizedDescription];
            DDLogError(@"%@", self.errorMessage);
            return [RACSignal return:@[]];
        }];

    // ...
    RACSignal *authenticatedStreams = [[readyAndReachable
        filter:^BOOL(id value) {
            return ([value boolValue] == YES); }]
        flattenMap:^RACStream *(id value) {
            return [[[self.client fetchAuthenticatedStreamList]
                deliverOn:[RACScheduler mainThreadScheduler]]
                catch:^RACSignal *(NSError *error) {
                    self.hasError = YES;
                    self.errorMessage = [error localizedDescription];
                    DDLogError(@"%@", self.errorMessage);
                    return [RACSignal return:@[]];
                }];
        }];

    RAC(self, authenticatedStreams) = [RACSignal
        combineLatest:@[executionSignal, authenticatedStreams]
        reduce:^id(NSNumber *executable, NSArray *streams) {
            DDLogInfo(@"Fetching authenticated stream list.");
            if ([executable boolValue] == YES && streams != nil) {
                DDLogInfo(@"%lu authenticated streams fetched.", [streams count]);
                return streams.sortBy(@"name");
            } else {
                DDLogInfo(@"No authenticated streams fetched.");
                return @[];
            }
        }];
}

@end
