//
//  APIClient.m
//  Shiver
//
//  Created by Bryan Veloso on 6/9/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "APIClient.h"

#import "AFJSONRequestOperation.h"
#import "OAuthViewController.h"

NSString * const kTwitchBaseURL = @"https://api.twitch.tv/kraken/";
NSString * const kRedirectURI = @"shiver://authorize";
NSString * const kClientID = @"rh02ow0o6qsss1psrb3q2cceg34tg9s";
NSString * const kClientSecret = @"rji9hs6u0wbj35snosv1n71ou0xpuqi";

@interface APIClient ()
@property (strong, nonatomic) AFOAuthCredential *credential;

- (NSMutableDictionary *)parseQueryStringsFromURL:(NSURL *)url;
@end

@implementation APIClient

+ (APIClient *)sharedClient
{
    static APIClient *_sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:kTwitchBaseURL] clientID:kClientID secret:kClientSecret];
        _sharedClient.credential = [AFOAuthCredential retrieveCredentialWithIdentifier:_sharedClient.serviceProviderIdentifier];
        if (_sharedClient.credential != nil) {
            [_sharedClient setAuthorizationHeaderWithCredential:_sharedClient.credential];
        }
    });

    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url clientID:(NSString *)clientID secret:(NSString *)secret
{
    self = [super initWithBaseURL:url clientID:clientID secret:secret];
    if (!self) {
        return nil;
    }

    [self setDefaultHeader:@"Accept" value:@"application/json"];
    [self setDefaultHeader:@"Client-ID" value:kClientID];
    return self;
}

- (BOOL)isAuthenticated
{
    return (self.credential != nil) ? YES : NO;
}

- (void)authorizeUsingResponseURL:(NSURL *)url
{
    [self clearAuthorizationHeader];

    NSString *accessToken = [[self parseQueryStringsFromURL:url] objectForKey:@"access_token"];
    self.credential = [AFOAuthCredential credentialWithOAuthToken:accessToken tokenType:@"OAuth"];
    [AFOAuthCredential storeCredential:self.credential withIdentifier:self.serviceProviderIdentifier];

    [self setAuthorizationHeaderWithCredential:self.credential];

    // Store `accessToken` in userDefaults.
    [[NSUserDefaults standardUserDefaults] setObject:self.credential.accessToken forKey:@"accessToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSMutableDictionary *)parseQueryStringsFromURL:(NSURL *)url
{
    NSMutableDictionary *queryStrings = [@{} mutableCopy];
    for (NSString *qs in [[url fragment] componentsSeparatedByString:@"&"]) {
        [queryStrings setValue:[[[[qs componentsSeparatedByString:@"="] objectAtIndex:1] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:[[qs componentsSeparatedByString:@"="] objectAtIndex:0]];
    }

    return queryStrings;
}

// This overrides AFOAuth2's method, since it's a douchebag.
- (void)setAuthorizationHeaderWithToken:(NSString *)token ofType:(NSString *)type
{
    [self setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"%@ %@", type, token]];
}

- (void)logout
{
    self.credential = nil;
    [AFOAuthCredential deleteCredentialWithIdentifier:self.serviceProviderIdentifier];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"accessToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
