//
//  Channel.m
//  Shiver
//
//  Created by Bryan Veloso on 6/9/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "Channel.h"

@implementation Channel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"displayName": @"display_name",
        @"logoImage": @"logo",
        @"createdAt": @"created_at",
        @"updatedAt": @"updated_at"
    };
}

@end
