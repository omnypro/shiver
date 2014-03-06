//
//  WindowViewModel.m
//  Shiver
//
//  Created by Bryan Veloso on 2/11/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "AccountManager.h"
#import "TwitchAPIClient.h"
#import "User.h"

#import "UserViewModel.h"

@interface UserViewModel ()

@property (nonatomic, strong) TwitchAPIClient *client;
@property (nonatomic, strong) User *user;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSURL *logoImageURL;

@end

@implementation UserViewModel

- (instancetype)init
{
    self = [super init];
    if (self == nil) return nil;

    _client = [TwitchAPIClient sharedClient];
    _user = nil;

    [self initializeSignals];

    return self;
}

- (void)initializeSignals
{
    // A combined singal for whether or not the account manager is
    // both ready and reachable.
    RACSignal *readySignal = [[AccountManager sharedManager] readySignal];
    RACSignal *readyAndReachable = [[AccountManager sharedManager] readyAndReachableSignal];

    // Observers.
    RAC(self, user) = [[[[readyAndReachable
        filter:^BOOL(id value) {
            return ([value boolValue] == YES); }]
        flattenMap:^RACStream *(id value) {
            return [self.client fetchUser]; }]
        map:^id(User *user) {
            DDLogInfo(@"%@", user ? [NSString stringWithFormat:@"We have a user. (%@)", user.name] : @"We don't have a user.");
            return user; }]
        catch:^RACSignal *(NSError *error) {
            self.hasError = YES;
            self.errorMessage = [error localizedDescription];
            DDLogError(@"%@", error);
            return [RACSignal return:nil];
        }];

    RAC(self, isLoggedIn) = readySignal;
    RAC(self, displayName) = RACObserve(self, user.displayName);
    RAC(self, name) = RACObserve(self, user.name);
    RAC(self, email) = RACObserve(self, user.email);
    RAC(self, logoImageURL) = RACObserve(self, user.logoImageURL);
}

- (RACSignal *)isUserFollowingChannel:(NSString *)channel
{
    DDLogInfo(@"Checking if '%@' follows '%@'.", self.name, channel);
    return [[[self.client isUser:self.name followingChannel:channel] map:^id(id responseObject) {
        return @(YES);
    }] catch:^RACSignal *(NSError *error) {
        long statusCode = [[[error userInfo] objectForKey:AFNetworkingOperationFailingURLResponseErrorKey] statusCode];
        DDLogError(@"Recieved a %ld from %@.", statusCode, NSStringFromSelector(_cmd));
        return [RACSignal return:@(NO)];
    }];
}

@end
