//
//  User.h
//  Shiver
//
//  Created by Bryan Veloso on 6/11/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "Mantle.h"

@interface User : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSNumber *_id;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *displayName;
@property (nonatomic, copy, readonly) NSString *email;

@property (nonatomic, copy, readonly) NSURL *logoImageURL;

@end
