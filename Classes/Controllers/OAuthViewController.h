//
//  OAuthViewController.h
//  Shiver
//
//  Created by Bryan Veloso on 6/9/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <RHPreferences/RHPreferences.h>
#import <WebKit/WebKit.h>

@class OAuthView;
@class RACReplaySubject;
@class RACSubject;

@interface OAuthViewController : NSViewController <RHPreferencesViewControllerProtocol>

@property (nonatomic, strong) RACReplaySubject *didLoginSubject;
@property (nonatomic, strong) RACReplaySubject *didLogoutSubject;
@property (nonatomic, strong) RACSubject *URLProtocolValueSubject;

- (id)init;

@end
