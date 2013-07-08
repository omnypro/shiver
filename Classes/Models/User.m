//
//  User.m
//  Shiver
//
//  Created by Bryan Veloso on 6/11/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "Mantle.h"
#import "TwitchAPIClient.h"

#import "User.h"

@implementation User

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"displayName": @"display_name",
        @"logoImageURL": @"logo",
    };
}

+ (NSValueTransformer *)logoImageURLJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

@end
