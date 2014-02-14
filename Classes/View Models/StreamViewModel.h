//
//  StreamViewModel.h
//  Shiver
//
//  Created by Bryan Veloso on 2/14/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

@class Stream;

@interface StreamViewModel : RVMViewModel

@property (nonatomic, strong, readonly) Stream *stream;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *game;
@property (nonatomic, strong, readonly) NSString *broadcaster;
@property (nonatomic, strong, readonly) NSURL *previewImageURL;
@property (nonatomic, strong, readonly) NSNumber *viewers;

- (instancetype)initWithStream:(Stream *)stream;

@end
