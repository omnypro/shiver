//
//  Stream.m
//  Shiver
//
//  Created by Bryan Veloso on 6/7/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "Stream.h"

#import "APIClient.h"
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
    return @{@"previewImageURL": @"preview"};
}

+ (NSValueTransformer *)previewImageURLJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)channelJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:Channel.class];
}

+ (void)streamListWithBlock:(void (^)(NSArray *streams, NSError *error))block {
    [[APIClient sharedClient] getPath:@"streams/followed" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        NSArray *streamsFromResponse = [responseObject valueForKeyPath:@"streams"];
        NSMutableArray *mutableStreams = [NSMutableArray arrayWithCapacity:[streamsFromResponse count]];

        for (NSDictionary *dictionary in streamsFromResponse) {
            NSError *error = nil;
            Stream *stream = [MTLJSONAdapter modelOfClass:self.class fromJSONDictionary:dictionary error:&error];
            [mutableStreams addObject:stream];
        }

        if (block) {
            block(mutableStreams, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block([NSArray array], error);
        }
    }];
}

@end
