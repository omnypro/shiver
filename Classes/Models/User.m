//
//  User.m
//  Shiver
//
//  Created by Bryan Veloso on 6/11/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "User.h"

#import "APIClient.h"
#import "Mantle.h"

@implementation User

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"displayName": @"display_name",
        @"logoImageURL": @"logo",
    };
}

+ (void)fetchUser
{
    [[APIClient sharedClient] getPath:@"user" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"responseObject: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@", error);
    }];
}

@end
