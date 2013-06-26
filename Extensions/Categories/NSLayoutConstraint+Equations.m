//
//  NSLayoutConstraint+Equations.m
//  Shiver
//
//  Created by Bryan Veloso on 6/24/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "NSLayoutConstraint+Equations.h"

@implementation NSLayoutConstraint (Equations)

+ (NSLayoutConstraint*) constraintWithFormula:(NSString *)formula LHS:(id)lhs RHS:(id)rhs
{
    //parse the formula
    //the format is property { = | < | > } [multiplier *] property [+ constant]
    //or if RHS is nil property { = | < | > } constant

    NSString *lhsPropertyString, *rhsPropertyString, *relationString;
    CGFloat multiplier = 1.0, constant = 0.0;

    static NSRegularExpression* expr = nil;
    static NSRegularExpression* constExpr = nil;
    static NSDictionary* layoutDict;
    static NSDictionary* relationDict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString* pattern = @"([a-zA-Z_][a-zA-Z0-9_]*)\\s*(=|<|>)\\s*(?:(\\d+(?:\\.\\d+)?)\\s*\\*)?\\s*([a-zA-Z_][a-zA-Z0-9_]+)\\s*(?:\\+\\s*(\\d+(?:\\.\\d+)?))?";
        NSError* err;
        expr = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&err];
        if (expr == nil) {
            NSLog(@"%@",err);
            abort();
        }

        pattern = @"([a-zA-Z_][a-zA-Z0-9_]*)\\s*(=|<|>)\\s*(\\d+(?:\\.\\d+)?)";
        constExpr = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&err];
        if (constExpr == nil) {
            NSLog(@"%@",err);
            abort();
        }

        layoutDict = @{
                       @"baseline" : @(NSLayoutAttributeBaseline),
                       @"bottom" : @(NSLayoutAttributeBottom),
                       @"centerX" : @(NSLayoutAttributeCenterX),
                       @"centerY" : @(NSLayoutAttributeCenterY),
                       @"height" : @(NSLayoutAttributeHeight),
                       @"leading" : @(NSLayoutAttributeLeading),
                       @"left" : @(NSLayoutAttributeLeft),
                       @"right" : @(NSLayoutAttributeRight),
                       @"top" : @(NSLayoutAttributeTop),
                       @"trailing" : @(NSLayoutAttributeTrailing),
                       @"width" : @(NSLayoutAttributeWidth)
                       };

        relationDict = @{
                         @"=" : @(NSLayoutRelationEqual),
                         @"<" : @(NSLayoutRelationLessThanOrEqual),
                         @">" : @(NSLayoutRelationGreaterThanOrEqual)
                         };
    });


    if (rhs == nil) {
        NSTextCheckingResult* rslt = [constExpr firstMatchInString:formula options:0 range:NSMakeRange(0, formula.length)];

        lhsPropertyString = [formula substringWithRange:[rslt rangeAtIndex:1]];
        relationString = [formula substringWithRange:[rslt rangeAtIndex:2]];
        constant = [[formula substringWithRange:[rslt rangeAtIndex:3]] floatValue];

        NSLayoutAttribute lhsAttribute = [layoutDict[lhsPropertyString] integerValue];
        NSLayoutRelation relation = [relationDict[relationString] integerValue];

        return [self constraintWithItem:lhs
                              attribute:lhsAttribute
                              relatedBy:relation
                                 toItem:nil
                              attribute:NSLayoutAttributeNotAnAttribute
                             multiplier:1.0
                               constant:constant];
    } else {

        NSTextCheckingResult* rslt = [expr firstMatchInString:formula options:0 range:NSMakeRange(0, formula.length)];

        //assign our strings
        lhsPropertyString = [formula substringWithRange:[rslt rangeAtIndex:1]];
        relationString = [formula substringWithRange:[rslt rangeAtIndex:2]];

        if ([rslt rangeAtIndex:3].length > 0) {
            multiplier = [[formula substringWithRange:[rslt rangeAtIndex:3]] floatValue];
        }

        rhsPropertyString = [formula substringWithRange:[rslt rangeAtIndex:4]];

        if ([rslt rangeAtIndex:5].length > 0) {
            constant = [[formula substringWithRange:[rslt rangeAtIndex:5]] floatValue];
        }

        //translate property strings to properties
        NSLayoutAttribute lhsAttribute = [layoutDict[lhsPropertyString] integerValue];
        NSLayoutAttribute rhsAttribute = [layoutDict[rhsPropertyString] integerValue];

        NSLayoutRelation relation = [relationDict[relationString] integerValue];

        return [self constraintWithItem:lhs
                              attribute:lhsAttribute
                              relatedBy:relation
                                 toItem:rhs
                              attribute:rhsAttribute
                             multiplier:multiplier
                               constant:constant];
    }
}

@end
