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

+ (void)userWithBlock:(void (^)(User *user, NSError *error))block
{
    [[APIClient sharedClient] getPath:@"user" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"responseObject: %@", responseObject);

        NSError *error = nil;
        User *user = [MTLJSONAdapter modelOfClass:self.class fromJSONDictionary:responseObject error:&error];

        if (block) {
            block(user, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@", error);

        if (block) {
            block(nil, nil);
        }
    }];
}

@end
