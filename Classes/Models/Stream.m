//
//  Stream.m
//  Shiver
//
//  Created by Bryan Veloso on 6/7/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "Stream.h"

#import "TwitchAPIClient.h"
#import "Mantle.h"
#import "Channel.h"

@implementation Stream

+ (NSDateFormatter *)dateFormatter {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    return dateFormatter;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{@"previewImageURL": @"preview.large"};
}

+ (NSValueTransformer *)previewImageURLJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)channelJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:Channel.class];
}

@end
