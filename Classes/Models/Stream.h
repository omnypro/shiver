//
//  Stream.h
//  Shiver
//
//  Created by Bryan Veloso on 6/7/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "Mantle.h"

@class Channel;

@interface Stream : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSNumber *_id;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *game;

@property (nonatomic, strong, readonly) Channel *channel;
@property (nonatomic, copy, readonly) NSString *broadcaster;
@property (nonatomic, copy, readonly) NSURL *previewImageURL;
@property (nonatomic, copy, readonly) NSNumber *viewers;

+ (void)fetchStreamListWithBlock:(void (^)(NSArray *streams, NSError *error))block;

@end
