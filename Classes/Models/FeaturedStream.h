//
//  FeaturedStream.h
//  Shiver
//
//  Created by Bryan Veloso on 7/4/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "MTLModel.h"

@class Stream;

@interface FeaturedStream : MTLModel

@property (nonatomic, strong, readonly) Stream *stream;
@property (nonatomic, copy, readonly) NSString *text;
@property (nonatomic, copy, readonly) NSURL *imageURL;

@end
