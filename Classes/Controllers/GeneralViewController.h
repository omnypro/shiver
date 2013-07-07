//
//  GeneralViewController.h
//  Shiver
//
//  Created by Bryan Veloso on 6/20/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <RHPreferences/RHPreferences.h>
#import <ServiceManagement/ServiceManagement.h>

@class Preferences;

@interface GeneralViewController : NSViewController <RHPreferencesViewControllerProtocol>

@property (nonatomic, strong) Preferences *preferences;

- (id)init;

@end
