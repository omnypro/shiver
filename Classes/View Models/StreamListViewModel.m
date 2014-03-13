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
    @weakify(self);

    RACSignal *reachableSignal = [[AccountManager sharedManager] reachableSignal];

    self.fetchCommand = [[RACCommand alloc]
        initWithEnabled:reachableSignal signalBlock:^RACSignal *(id input) {
            @strongify(self);
            DDLogInfo(@"Fetching stream lists.");
            return [[RACSignal
                    combineLatest:@[
                        [self updateFeaturedStreams],
                        [[self updateAuthenticatedStreams] catchTo:[RACSignal return:@[]]]]
                    reduce:^id(NSArray *featuredStreams, NSArray *authenticatedStreams) {
                        return RACTuplePack(featuredStreams, authenticatedStreams); }]
                    deliverOn:[RACScheduler mainThreadScheduler]];
        }];
    [self.fetchCommand.errors subscribeNext:^(NSError *error) {
        @strongify(self);
        self.hasError = YES;
        self.errorMessage = [error localizedDescription];
        DDLogError(@"%@", self.errorMessage);
    }];

    // ...
    RAC(self, errorMessage) = [RACSignal return:@"We're lacking Internets."];
    RAC(self, hasError) = [reachableSignal not];
    RAC(self, isLoading, @YES) = [[self.fetchCommand enabled] not];

    // ...
    RAC(self, featuredStreams) = [self.fetchCommand.executionSignals.flatten
        map:^id(RACTuple *tuple) {
            DDLogInfo(@"Successfully fetched featured stream list.");
            NSArray *streams = tuple[0];
            if (streams != nil) {
                DDLogInfo(@"%lu featured streams fetched.", [streams count]);
                return streams.sortBy(@"name");
            } else {
                DDLogInfo(@"No featured streams fetched.");
                return @[];
            }
        }];

    // ...
    RAC(self, authenticatedStreams) = [self.fetchCommand.executionSignals.flatten
        map:^id(RACTuple *tuple) {
            DDLogInfo(@"Successfully fetched authenticated stream list.");
            NSArray *streams = tuple[1];
            if (streams != nil) {
                DDLogInfo(@"%lu authenticated streams fetched.", [streams count]);
                return streams.sortBy(@"name");
            } else {
                DDLogInfo(@"No authenticated streams fetched.");
                return @[];
            }
        }];
}

- (RACSignal *)updateAuthenticatedStreams
{
    DDLogInfo(@"Updating authenticated stream list.");
    return [self.client fetchAuthenticatedStreamList];
}

- (RACSignal *)updateFeaturedStreams
{
    DDLogInfo(@"Updating featured stream list.");
    return [RACSignal
        combineLatest:@[
            [self.client fetchFeaturedStreamList],
            [[self.client fetchAuthenticatedStreamList] catchTo:[RACSignal return:@[]]]]
        reduce:^id(NSArray *featured, NSArray *authenticated) {
            return [[[featured.rac_sequence
                filter:^BOOL(StreamViewModel *stream) {
                    NSNumber *state = @(![authenticated containsObject:stream]);
                    return [state boolValue]; }]
                map:^id(StreamViewModel *stream) {
                    return stream;
                }] array];
            }];
}

@end
