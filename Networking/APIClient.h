//
//  APIClient.h
//  Shiver
//
//  Created by Bryan Veloso on 6/9/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "AFOAuth2Client.h"

extern NSString * const kTwitchBaseURL;
extern NSString * const kRedirectURI;
extern NSString * const kClientID;

@interface APIClient : AFOAuth2Client

@property (nonatomic, assign) BOOL isAuthenticated;

+ (APIClient *)sharedClient;

- (void)signOut;

@end
