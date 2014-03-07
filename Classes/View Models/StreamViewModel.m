//
//  StreamViewModel.m
//  Shiver
//
//  Created by Bryan Veloso on 2/14/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "Channel.h"
#import "Stream.h"

#import "StreamViewModel.h"

@implementation StreamViewModel

- (instancetype)initWithStream:(Stream *)stream
{
    NSCParameterAssert(stream != nil);
    self = [super init];
    if (self == nil) return nil;

    _stream = stream;

    [self initializeSignals];

    return self;
}

- (void)initializeSignals
{
    RAC(self, game) = RACObserve(self, stream.game);
    RAC(self, broadcaster) = RACObserve(self, stream.broadcaster);
    RAC(self, previewImageURL) = RACObserve(self, stream.previewImageURL);
    RAC(self, viewers) = RACObserve(self, stream.viewers);

    RAC(self, channel) = RACObserve(self, stream.channel);
    RAC(self, name) = RACObserve(self, stream.channel.name);
    RAC(self, displayName) = RACObserve(self, stream.channel.displayName);
    RAC(self, url) = RACObserve(self, stream.channel.url);
    RAC(self, createdAt) = RACObserve(self, stream.channel.createdAt);
    RAC(self, updatedAt) = RACObserve(self, stream.channel.updatedAt);
    RAC(self, logoImageURL) = RACObserve(self, stream.channel.logoImageURL);
    RAC(self, status) = RACObserve(self, stream.channel.status);

    RAC(self, hlsURL) = [RACObserve(self, name)
        map:^id(id value) {
            return [NSURL URLWithString:[NSString stringWithFormat:@"http://twitch.tv/%@/hls", value]];
        }];
}

#pragma mark NSObject

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p> { name = %@ }", self.class, self, self.name];
}

- (NSUInteger)hash
{
    return [self.name hash];
}

- (BOOL)isEqual:(StreamViewModel *)viewModel
{
    return [self.name isEqual:[viewModel name]];
}

-(NSComparisonResult)compare:(StreamViewModel *)otherViewModel
{
    NSComparisonResult comp_result = [self compare:otherViewModel];
    return comp_result;
}

@end
