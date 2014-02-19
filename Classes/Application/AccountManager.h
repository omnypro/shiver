//
//  AccountManager.h
//  Shiver
//
//  Created by Bryan Veloso on 2/11/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "AFOAuth2Client.h"

@interface AccountManager : NSObject

@property (nonatomic, strong) AFOAuthCredential *credential;

+ (AccountManager *)sharedManager;

- (RACSignal *)readySignal;
- (RACSignal *)reachableSignal;
- (RACSignal *)readyAndReachableSignal;

@end
