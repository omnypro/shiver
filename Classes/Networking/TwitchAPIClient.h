//
//  TwitchAPIClient.h
//  Shiver
//
//  Created by Bryan Veloso on 6/9/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>

#import "AFOAuth2Client.h"

extern NSString *const kTwitchBaseURL;
extern NSString *const kRedirectURI;
extern NSString *const kClientID;

@interface TwitchAPIClient : AFOAuth2Client

@property (nonatomic, strong) AFOAuthCredential *credential;
@property (nonatomic, strong) NSURL *authorizationURL;

+ (TwitchAPIClient *)sharedClient;

- (void)logout;

- (RACSignal *)authorizeUsingResponseURL:(NSURL *)url;
- (RACSignal *)fetchUser;
- (RACSignal *)fetchAuthenticatedStreamList;
- (RACSignal *)fetchFeaturedStreamList;
- (RACSignal *)isUser:(NSString *)user followingChannel:(NSString *)channel;
- (RACSignal *)haveUser:(NSString *)user followChannel:(NSString *)channel;
- (RACSignal *)haveUser:(NSString *)user unfollowChannel:(NSString *)channel;

@end
