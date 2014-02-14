//
//  StreamViewModel.m
//  Shiver
//
//  Created by Bryan Veloso on 2/14/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "Stream.h"

#import "StreamViewModel.h"

@implementation StreamViewModel

- (instancetype)initWithStream:(Stream *)stream
{
    NSCParameterAssert(stream != nil);
    self = [super init];
    if (self == nil) return nil;

    _stream = stream;
    _name = stream.name;
    _game = stream.game;
    _broadcaster = stream.broadcaster;
    _previewImageURL = stream.previewImageURL;
    _viewers = stream.viewers;

    return self;
}

@end
