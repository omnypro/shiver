//
//  TwitchAPIClient.m
//  Shiver
//
//  Created by Bryan Veloso on 6/9/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "AFJSONRequestOperation.h"
#import "Mantle.h"
#import "LoginViewController.h"
#import "Stream.h"
#import "StreamViewModel.h"
#import "User.h"

#import "TwitchAPIClient.h"

NSString * const kTwitchBaseURL = @"https://api.twitch.tv/kraken/";
NSString * const kRedirectURI = @"shiver://authorize";
NSString * const kClientID = @"rh02ow0o6qsss1psrb3q2cceg34tg9s";
NSString * const kClientSecret = @"rji9hs6u0wbj35snosv1n71ou0xpuqi";

@interface TwitchAPIClient ()

@property (nonatomic, strong) User *user;

- (NSMutableDictionary *)parseQueryStringsFromURL:(NSURL *)url;

@end

@implementation TwitchAPIClient

+ (TwitchAPIClient *)sharedClient
{
    static TwitchAPIClient *_sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:kTwitchBaseURL] clientID:kClientID secret:kClientSecret];
        _sharedClient.authorizationURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@oauth2/authorize/?client_id=%@&redirect_uri=%@&response_type=token&scope=user_read+user_follows_edit", kTwitchBaseURL, kClientID, kRedirectURI]];
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
    if (self == nil) { return nil; }

    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [self setDefaultHeader:@"Accept" value:@"application/json"];
    [self setDefaultHeader:@"Client-ID" value:kClientID];

    return self;
}

- (NSMutableDictionary *)parseQueryStringsFromURL:(NSURL *)url
{
    NSMutableDictionary *queryStrings = [@{} mutableCopy];
    for (NSString *qs in [[url fragment] componentsSeparatedByString:@"&"]) {
        [queryStrings
            setValue:[[[qs componentsSeparatedByString:@"="][1]
            stringByReplacingOccurrencesOfString:@"+" withString:@" "]
            stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
            forKey:[qs componentsSeparatedByString:@"="][0]];
    }

    return queryStrings;
}

- (void)setAuthorizationHeaderWithToken:(NSString *)token ofType:(NSString *)type
{
    // This overrides AFOAuth2's method, since it's a douchebag.
    [self setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"%@ %@", type, token]];
}

- (RACSignal *)authorizeUsingResponseURL:(NSURL *)url
{
    DDLogInfo(@"Authentication: Authorizing with provided URL.");
    NSString *accessToken = [self parseQueryStringsFromURL:url][@"access_token"];
    DDLogVerbose(@"Authentication: (Access Token) %@", accessToken);

    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        AFOAuthCredential *credential;
        credential = [AFOAuthCredential credentialWithOAuthToken:accessToken tokenType:@"OAuth"];
        [AFOAuthCredential storeCredential:credential withIdentifier:self.serviceProviderIdentifier];
        [self setAuthorizationHeaderWithCredential:credential];

        [subscriber sendNext:credential];
        [subscriber sendCompleted];
        return nil;
    }] doNext:^(AFOAuthCredential *credential) {
        self.credential = credential;

        // Store `accessToken` in userDefaults.
        [[NSUserDefaults standardUserDefaults] setObject:credential.accessToken forKey:@"accessToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }];
}

- (void)logout
{
    [AFOAuthCredential deleteCredentialWithIdentifier:self.serviceProviderIdentifier];
    [self setAuthorizationHeaderWithCredential:nil];
    self.credential = nil;

    // Remove `accessToken` from userDefaults.
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"accessToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (RACSignal *)fetchUser
{
    DDLogInfo(@"Fetching user from the Twitch API.");
    return [[self enqueueRequestWithMethod:@"GET" path:@"user" parameters:nil]
        map:^id(id responseObject) {
            NSError *error;
            User *user = [MTLJSONAdapter modelOfClass:User.class fromJSONDictionary:responseObject error:&error];
            return user;
        }];
}

- (RACSignal *)fetchStream:(NSString *)stream
{
    DDLogInfo(@"Fetching stream from the Twitch API.");
    NSString *path = [NSString stringWithFormat:@"streams/%@", stream];
    return [[[self enqueueRequestWithMethod:@"GET" path:path parameters:nil]
        map:^id(id responseObject) { return [responseObject valueForKeyPath:@"stream"]; }]
        map:^id(id dictionary) {
            NSError *error;
            Stream *stream = [MTLJSONAdapter modelOfClass:Stream.class fromJSONDictionary:dictionary error:&error];
            StreamViewModel *viewModel = [[StreamViewModel alloc] initWithStream:stream];
            return viewModel;
        }];
}

- (RACSignal *)fetchAuthenticatedStreamList
{
    DDLogInfo(@"Fetching authenticated stream list from the Twitch API.");
    return [[[self enqueueRequestWithMethod:@"GET" path:@"streams/followed" parameters:nil]
        map:^id(id responseObject) { return [responseObject valueForKeyPath:@"streams"]; }]
        map:^id(NSArray *streamsFromResponse) {
            return [[streamsFromResponse.rac_sequence map:^id(NSDictionary *dictionary) {
                NSError *error = nil;
                Stream *stream = [MTLJSONAdapter modelOfClass:Stream.class fromJSONDictionary:dictionary error:&error];
                StreamViewModel *viewModel = [[StreamViewModel alloc] initWithStream:stream];
                return viewModel;
            }] array];
        }];
}

- (RACSignal *)fetchFeaturedStreamList
{
    DDLogInfo(@"Fetching featured stream list from the Twitch API.");
    return [[[self enqueueRequestWithMethod:@"GET" path:@"streams/featured" parameters:nil]
        map:^id(id responseObject) { return [responseObject valueForKeyPath:@"featured"]; }]
        map:^id(NSDictionary *streamsFromResponse) {
            // Twitch's featured streams nests a Stream object alongside
            // metadata that is used for their front page. We don't need
            // this data, so we'll just grab the nested object.
            streamsFromResponse = [streamsFromResponse valueForKeyPath:@"stream"];
            return [[streamsFromResponse.rac_sequence map:^id(NSMutableDictionary *dictionary) {
                NSError *error = nil;
                Stream *stream = [MTLJSONAdapter modelOfClass:Stream.class fromJSONDictionary:dictionary error:&error];
                StreamViewModel *viewModel = [[StreamViewModel alloc] initWithStream:stream];
                return viewModel;
            }] array];
        }];
}

- (RACSignal *)isUser:(NSString *)user followingChannel:(NSString *)channel
{
    NSString *path = [NSString stringWithFormat:@"users/%@/follows/channels/%@", user, channel];
    return [self enqueueRequestWithMethod:@"GET" path:path parameters:nil];
}

- (RACSignal *)haveUser:(NSString *)user followChannel:(NSString *)channel
{
    NSString *path = [NSString stringWithFormat:@"users/%@/follows/channels/%@", user, channel];
    return [self enqueueRequestWithMethod:@"PUT" path:path parameters:nil];
}

- (RACSignal *)haveUser:(NSString *)user unfollowChannel:(NSString *)channel
{
    NSString *path = [NSString stringWithFormat:@"users/%@/follows/channels/%@", user, channel];
    return [self enqueueRequestWithMethod:@"DELETE" path:path parameters:nil];
}

- (RACSignal *)enqueueRequestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters
{
    return [[RACSignal
        createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            NSURLRequest *request = [self requestWithMethod:method path:path parameters:parameters];
            AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [subscriber sendNext:responseObject];
            [subscriber sendCompleted];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [subscriber sendError:error];
        }];

        [self enqueueHTTPRequestOperation:operation];
        return [RACDisposable disposableWithBlock:^{ [operation cancel]; }];
    }] replayLazily];
}

@end
