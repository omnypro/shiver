//
//  StreamListViewModel.h
//  Shiver
//
//  Created by Bryan Veloso on 2/14/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "RVMViewModel.h"

@interface StreamListViewModel : RVMViewModel

@property (nonatomic, strong) RACCommand *fetchCommand;

@property (nonatomic, strong) NSArray *authenticatedStreams;
@property (nonatomic, strong) NSArray *featuredStreams;
@property (nonatomic, strong) NSString *errorMessage;

@property (nonatomic, assign) BOOL hasError;
@property (nonatomic, assign) BOOL isLoading;

@end
