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
        [queryStrings setValue:[[[qs componentsSeparatedByString:@"="][1] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:[qs componentsSeparatedByString:@"="][0]];
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

    // Remove `accessToken` from userDefaults.
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"accessToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (RACSignal *)authorizeUsingResponseURL:(NSURL *)url
{
    DDLogInfo(@"Authentication: Authorizing with provided URL.");
    NSString *accessToken = [self parseQueryStringsFromURL:url][@"access_token"];
    DDLogVerbose(@"Authentication: (Access Token) %@", accessToken);
    self.credential = [AFOAuthCredential credentialWithOAuthToken:accessToken tokenType:@"OAuth"];
    [AFOAuthCredential storeCredential:self.credential withIdentifier:self.serviceProviderIdentifier];
    [self setAuthorizationHeaderWithCredential:self.credential];

    // Store `accessToken` in userDefaults.
    [[NSUserDefaults standardUserDefaults] setObject:self.credential.accessToken forKey:@"accessToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    RACReplaySubject *subject = [RACReplaySubject subject];
    [subject sendNext:self.credential];
    [subject sendCompleted];
    return [subject deliverOn:[RACScheduler scheduler]];
}

- (RACSignal *)fetchUser
{
    return [[self enqueueRequestWithMethod:@"GET" path:@"user" parameters:nil]
        map:^id(id responseObject) {
            NSError *error = nil;
            User *user = [MTLJSONAdapter modelOfClass:User.class fromJSONDictionary:responseObject error:&error];
            return user;
        }];
}

- (RACSignal *)fetchAuthenticatedStreamList
{
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
    RACReplaySubject *subject = [RACReplaySubject subject];
    NSURLRequest *request = [self requestWithMethod:method path:path parameters:parameters];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [subject sendNext:responseObject];
        [subject sendCompleted];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [subject sendError:error];
    }];
    [self enqueueHTTPRequestOperation:operation];

    return [subject deliverOn:[RACScheduler scheduler]];
}

@end
