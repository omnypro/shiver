//
//  APIClient.h
//  Shiver
//
//  Created by Bryan Veloso on 6/9/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "AFHTTPClient.h"

extern NSString * const kTwitchBaseURL;

@interface APIClient : AFHTTPClient

@property (nonatomic, assign) BOOL isAuthenticated;

+ (APIClient *)sharedClient;

#define clientID @"rh02ow0o6qsss1psrb3q2cceg34tg9s"
#define clientSecret @"rji9hs6u0wbj35snosv1n71ou0xpuqi"

@end
