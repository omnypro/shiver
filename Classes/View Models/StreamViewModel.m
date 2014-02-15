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
    _channel = stream.channel;

    _name = _channel.name;
    _game = stream.game;
    _broadcaster = stream.broadcaster;
    _hlsURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://twitch.tv/%@/hls", _name]];
    _previewImageURL = stream.previewImageURL;
    _viewers = stream.viewers;

    return self;
}

@end
