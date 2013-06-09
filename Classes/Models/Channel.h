//
//  Channel.h
//  Shiver
//
//  Created by Bryan Veloso on 6/9/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "Mantle.h"

@interface Channel : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSNumber *_id;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *displayName;
@property (nonatomic, copy, readonly) NSString *game;
@property (nonatomic, copy, readonly) NSURL *url;

@property (nonatomic, copy, readonly) NSDate *createdAt;
@property (nonatomic, copy, readonly) NSDate *updatedAt;
@property (nonatomic, copy, readonly) NSString *status;
@property (nonatomic, copy, readonly) NSURL *logoImage;

@end
