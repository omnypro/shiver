//
//  WindowViewModel.h
//  Shiver
//
//  Created by Bryan Veloso on 2/11/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "RVMViewModel.h"

@interface UserViewModel : RVMViewModel

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) NSString *email;
@property (nonatomic, readonly) NSURL *logoImageURL;

@property (nonatomic, assign) BOOL isLoggedIn;

@end
