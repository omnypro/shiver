//
//  StreamViewModel.h
//  Shiver
//
//  Created by Bryan Veloso on 2/14/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

@class Channel;
@class Stream;

@interface StreamViewModel : RVMViewModel

@property (nonatomic, strong, readonly) Channel *channel;
@property (nonatomic, strong, readonly) Stream *stream;

// Shortcuts to synced data from the Stream class.
@property (nonatomic, strong, readonly) NSString *game;
@property (nonatomic, strong, readonly) NSString *broadcaster;
@property (nonatomic, strong, readonly) NSURL *previewImageURL;
@property (nonatomic, strong, readonly) NSNumber *viewers;

// Shortcuts to synced data from the Channel class.
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *displayName;
@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, strong, readonly) NSDate *createdAt;
@property (nonatomic, strong, readonly) NSDate *updatedAt;
@property (nonatomic, strong, readonly) NSURL *logoImageURL;
@property (nonatomic, strong, readonly) NSString *status;

@property (nonatomic, strong, readonly) NSURL *hlsURL;

- (instancetype)initWithStream:(Stream *)stream;

@end
