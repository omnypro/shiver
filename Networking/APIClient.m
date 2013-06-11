//
//  APIClient.m
//  Shiver
//
//  Created by Bryan Veloso on 6/9/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "APIClient.h"

#import "AFJSONRequestOperation.h"

NSString * const kTwitchBaseURL = @"https://api.twitch.tv/kraken/";
NSString * const kRedirectURI = @"shiver://authorize";
NSString * const kClientID = @"rh02ow0o6qsss1psrb3q2cceg34tg9s";
NSString * const kClientSecret = @"rji9hs6u0wbj35snosv1n71ou0xpuqi";

@interface APIClient ()

@property (strong, nonatomic) AFOAuthCredential *credential;

@end

@implementation APIClient

+ (APIClient *)sharedClient
{
    static APIClient *_sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:kTwitchBaseURL]];
        _sharedClient.credential = [AFOAuthCredential retrieveCredentialWithIdentifier:_sharedClient.serviceProviderIdentifier];
        if (_sharedClient.credential != nil) {
            [_sharedClient setAuthorizationHeaderWithCredential:_sharedClient.credential];
        }
    });

    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }

    [self setDefaultHeader:@"Accept" value:@"application/vnd.twitchtv.v2+json"];
    [self setDefaultHeader:@"Client-ID" value:kClientID];

    self.credential = [AFOAuthCredential retrieveCredentialWithIdentifier:self.serviceProviderIdentifier];
    if (self.credential != nil) {
        [self setAuthorizationHeaderWithCredential:self.credential];
    }

    return self;
}

- (void)signOut
{
    self.credential = nil;
    [AFOAuthCredential deleteCredentialWithIdentifier:self.serviceProviderIdentifier];
}

@end
