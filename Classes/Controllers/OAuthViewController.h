//
//  OAuthViewController.h
//  Shiver
//
//  Created by Bryan Veloso on 6/9/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <RHPreferences/RHPreferences.h>
#import <WebKit/WebKit.h>

@class OAuthView;

@interface OAuthViewController : NSViewController <RHPreferencesViewControllerProtocol>

@property (nonatomic, strong, readonly) RACSubject *didLoginSubject;
@property (nonatomic, strong, readonly) RACSubject *URLProtocolValueSubject;

@end
