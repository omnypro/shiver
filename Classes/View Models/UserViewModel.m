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
    RACSignal *readyAndReachable = [[AccountManager sharedManager] readyAndReachableSignal];

    // Signals related to credential checking.
    RACSignal *credentialSignal = RACObserve(AccountManager.sharedManager, credential);
    RACSignal *hasCredential = [credentialSignal map:^(AFOAuthCredential *credential) { return @(credential != nil); }];

    // Observers.
    RAC(self, user) = [[RACSignal
        combineLatest:@[readyAndReachable, hasCredential, [self.client fetchUser]]
        reduce:^id(NSNumber *readyAndReachable, NSNumber *hasCredential, User *user){
            if ([readyAndReachable boolValue] && [hasCredential boolValue] && user != nil) {
                DDLogInfo(@"We have a user. (%@)", user.name);
                return user;
            } else {
                DDLogInfo(@"We don't have a user.");
                return nil;
            } }]
        catch:^RACSignal *(NSError *error) {
            self.hasError = YES;
            self.errorMessage = [error localizedDescription];
            DDLogError(@"%@", self.errorMessage);
            return [RACSignal empty];
        }];

    RAC(self, isLoggedIn, @NO) = [RACObserve(self, user)
        map:^id(id value) {
            return @(value != nil);
        }];

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
