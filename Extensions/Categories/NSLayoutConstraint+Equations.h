//
//  NSLayoutConstraint+Equations.h
//  Shiver
//
//  Created by Bryan Veloso on 6/24/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSLayoutConstraint (Equations)

+ (NSLayoutConstraint*) constraintWithFormula:(NSString*)formula LHS:(id)lhs RHS:(id)rhs;

@end
