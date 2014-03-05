//
//  LogFormatter.m
//  Shiver
//
//  Created by Bryan Veloso on 3/5/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "LogFormatter.h"

@implementation LogFormatter

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    NSString *logLevel;
    switch (logMessage->logFlag)
    {
        case LOG_FLAG_ERROR : logLevel = @"E"; break;
        case LOG_FLAG_WARN  : logLevel = @"W"; break;
        case LOG_FLAG_INFO  : logLevel = @"I"; break;
        case LOG_FLAG_DEBUG : logLevel = @"D"; break;
        default             : logLevel = @"V"; break;
    }

    NSString *logFile = [[NSString stringWithFormat:@"%s", logMessage->file] lastPathComponent];

    return [NSString stringWithFormat:@"%@ [%@:%d in %s] %@", logLevel, logFile, logMessage->lineNumber, logMessage->function, logMessage->logMsg];
}

@end
