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
    RAC(self, isLoading, @YES) = [RACSignal
        combineLatest:@[
            RACObserve(self, authenticatedStreams),
            RACObserve(self, featuredStreams)]
        reduce:^id(NSArray *authenticatedStreams, NSArray *featuredStreams) {
            return @(featuredStreams == nil);
        }];

    // A combined singal for whether or not the account manager is
    // both ready and reachable. Also: signal related to credential checking.
    RACSignal *readyAndReachable = [[AccountManager sharedManager] readyAndReachableSignal];
    RACSignal *hasCredential = [RACObserve(AccountManager.sharedManager, credential) map:^(AFOAuthCredential *credential) { return @(credential != nil); }];

    RACSignal *fetchAuthenticatedStreams = [[self.client fetchAuthenticatedStreamList] deliverOn:[RACScheduler mainThreadScheduler]];
    RACSignal *fetchFeaturedStreams = [[self.client fetchFeaturedStreamList] deliverOn:[RACScheduler mainThreadScheduler]];

    self.refreshCommand = [[RACCommand alloc]
        initWithSignalBlock:^RACSignal *(id input) {
            return [RACSignal return:@1];
        }];

    // Observes -readyAndReachable and our refresh action and returns whenever
    // either of those signals returns a value.
    RACSignal *executionSignal = [RACSignal merge:@[readyAndReachable, [self.refreshCommand.executionSignals flatten]]];

    // ...
    RAC(self, featuredStreams) = [[RACSignal
        combineLatest:@[executionSignal, fetchFeaturedStreams, fetchAuthenticatedStreams]
        reduce:^id(NSNumber *executable, NSArray *featuredStreams, NSArray *authenticatedStreams){
            DDLogInfo(@"Application (%@): Fetching featured stream list.", [self class]);
            if (featuredStreams != nil) {
                // If authenticated streams are a thing, its contents from
                // the featured stream list.
                DDLogInfo(@"Application (%@): %lu streams fetched.", [self class], [featuredStreams count]);
                return [[featuredStreams.sortBy(@"name").rac_sequence
                    map:^id(StreamViewModel *stream) {
                        if ([authenticatedStreams containsObject:stream]) { [stream setIsFollowed:YES]; }
                        return stream;
                    }] array];
            } else {
                DDLogInfo(@"Application (%@): No featured streams fetched.", [self class]);
                return @[];
            } }]
        catch:^RACSignal *(NSError *error) {
            DDLogError(@"Application (%@): (Error) %@", [self class], error);
            self.hasError = YES;
            self.errorMessage = [error localizedDescription];
            return [RACSignal return:@[]];
        }];

    // ...
    RAC(self, authenticatedStreams) = [[RACSignal
        combineLatest:@[executionSignal, hasCredential, fetchAuthenticatedStreams]
        reduce:^id(NSNumber *executable, NSNumber *hasCredential, NSArray *streams) {
            DDLogInfo(@"Application (%@): Fetching authenticated stream list.", [self class]);
            if ([hasCredential boolValue] == YES && streams != nil) {
                DDLogInfo(@"Application (%@): %lu authenticated streams fetched.", [self class], [streams count]);
                return streams.sortBy(@"name");
            } else {
                DDLogInfo(@"Application (%@): No authenticated streams fetched.", [self class]);
                return @[];
            } }]
        catch:^RACSignal *(NSError *error) {
            DDLogError(@"Application (%@): (Error) %@", [self class], error);
            self.hasError = YES;
            self.errorMessage = [error localizedDescription];
            return [RACSignal return:@[]];
        }];
}

@end
