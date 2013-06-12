//
//  Stream.m
//  Shiver
//
//  Created by Bryan Veloso on 6/7/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "Stream.h"

#import "APIClient.h"
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
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:Channel.class];
}

+ (void)fetchItems
{
    NSURL *baseURL = [[NSURL alloc] initWithString:@"https://api.twitch.tv/kraken/"];
    OVCClient *twitchClient = [[OVCClient alloc] initWithBaseURL:baseURL];
    OVCQuery *featuredStreams = [OVCQuery queryWithMethod:OVCQueryMethodGet path:@"streams/featured" parameters:nil modelClass:Stream.class objectKeyPath:@"featured"];
//    OVCQuery *featuredStreams = [OVCQuery queryWithMethod:OVCQueryMethodGet path:@"streams/featured" modelClass:Stream.class];

    [twitchClient executeQuery:featuredStreams completionBlock:^(OVCRequestOperation *operation, NSArray *streams, NSError *error) {
        if (!error) {
            NSLog(@"%@", streams);
        }
    }];
}

@end
