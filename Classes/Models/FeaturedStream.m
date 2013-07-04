//
//  FeaturedStream.m
//  Shiver
//
//  Created by Bryan Veloso on 7/4/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "Stream.h"

#import "FeaturedStream.h"

@implementation FeaturedStream

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"imageURL": @"image",
     };
}

+ (NSValueTransformer *)streamJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:Stream.class];
}

@end
