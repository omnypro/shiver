//
//  StreamViewModel.m
//  Shiver
//
//  Created by Bryan Veloso on 2/14/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "Channel.h"
#import "NSDate+HumanizedTime.h"
#import "Stream.h"

#import "StreamViewModel.h"

@implementation StreamViewModel

- (instancetype)initWithStream:(Stream *)stream
{
    NSCParameterAssert(stream != nil);
    self = [super init];
    if (self == nil) return nil;

    _stream = stream;
    _game = stream.game;
    _broadcaster = stream.broadcaster;
    _previewImageURL = stream.previewImageURL;
    _viewers = stream.viewers;

    _channel = stream.channel;
    _name = _channel.name;
    _displayName = _channel.displayName;
    _url = _channel.url;
    _createdAt = _channel.createdAt;
    _updatedAt = _channel.updatedAt;
    _liveSince = [_channel.updatedAt stringWithHumanizedTimeDifference:NSDateHumanizedSuffixNone withFullString:YES];
    _logoImageURL = _channel.logoImageURL;
    _status = _channel.status;

    _hlsURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://twitch.tv/%@/hls", _name]];

    return self;
}

@end
