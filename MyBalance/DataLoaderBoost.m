//
//  DataLoaderBoost.m
//  MyBalance
//
//  Created by Tommy Sparber on 9/01/2016.
//  Copyright © 2016 Tommy Sparber. All rights reserved.
//

#import "DataLoaderBoost.h"

#define BOOST_CHECK_URL @"http://m.telstra.com/boost/viewBalanceAction.mml?a=view"

@interface DataLoaderBoost() <NSURLSessionDownloadDelegate>
@property (strong, nonatomic) NSURLSessionConfiguration * urlSessionConfiguration;
@property (strong, nonatomic) NSURLSession *urlSession;
@property (strong, nonatomic) NSError *error;
@end

@implementation DataLoaderBoost

- (instancetype)init {
    self = [super init];

    if (self) {
        self.urlSession = [NSURLSession sessionWithConfiguration:[self setupURLSessionConfiguration] delegate:self delegateQueue:nil];
    }

    return self;
}

- (NSURLSessionConfiguration *)setupURLSessionConfiguration {
    NSURLSessionConfiguration *urlSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];

    urlSessionConfiguration.HTTPMaximumConnectionsPerHost = 1;
    urlSessionConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;

    return urlSessionConfiguration;
}

- (void)refresh {
    NSLog(@"Start loading...");
    NSURLSessionDownloadTask *getDataTask = [self.urlSession downloadTaskWithURL:[NSURL URLWithString:BOOST_CHECK_URL]];
    [getDataTask resume];
}

#pragma mark DownloadDelegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSLog(@"didFinishDownloadingToURL");

    [self parseData:[NSString stringWithContentsOfURL:location usedEncoding:nil error:nil]];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {

    if (error) {
        NSLog(@"did complete with error: %@", error);
        [self parseData:@""];
    } else {
        error = self.error;
        self.error = nil;
    }

    if (self.delegate) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate dataDidChange:self withError:error];
        });
    }
}

#pragma mark DataParsing
- (void)parseData:(NSString *)data {
    NSError *error = nil;
    NSArray *matches = nil;
    NSString *plan = nil;
    NSInteger maxIncludedData = 1000;
    NSInteger maxBonusWeekendData = 500;
    NSInteger maxExpiry = 30;

    NSString *pattern = @"<div class=\"container-row\">.*<p>([A-Z]+)<sup>&reg;</sup></p>.*<p> Expires ([0-9/ :]+)</p>.*</div>";
    matches = [self matchData:data withPattern:pattern error:&error];

    if ([matches count] == 2) {
        plan = [matches objectAtIndex:0];

        if ([plan isEqualToString:@"UNLTD"]) {
            maxIncludedData = 3000;
            maxBonusWeekendData = 2000;
        } else if ([plan isEqualToString:@"ULTRA"]) {
            maxIncludedData = 1000;
            maxBonusWeekendData = 500;
        } else {
            NSLog(@"Plan: %@ unknown!", plan);
        }

        NSString *expiry = [matches objectAtIndex:1];

        NSDateFormatter *format = [[NSDateFormatter alloc] init];
        [format setDateFormat:@"dd/MM/yyyy HH:mm:ss"];

        NSDate *date = [format dateFromString:expiry];
        NSTimeInterval timeFromNow = [date timeIntervalSinceNow];
        float daysFromNow = (float)timeFromNow / 60 / 60 / 24;

        self.expires = [NSString stringWithFormat:@"%.1fd / %dd", daysFromNow, (int)maxExpiry];
        self.percentExpires = daysFromNow / maxExpiry;
    } else {
        self.expires = @"";
        self.percentExpires = 0;
    }

    pattern = @"<div class=\"container-row\">.*<p>Inc Data</p>.*<p>([0-9.,]+)([A-Z]+) Expires ([0-9/ :]+)</p>.*</div>";
    matches = [self matchData:data withPattern:pattern error:&error];

    if ([matches count] == 3) {
        NSString *value = [[matches objectAtIndex:0] stringByReplacingOccurrencesOfString:@"," withString:@""];
        NSString *unit = [matches objectAtIndex:1];

        float valueFloat = [value floatValue];
        NSString *valueString = [NSString stringWithFormat:@"%d", (int)[value integerValue]];
        if ([unit isEqualToString:@"GB"]) {
            if (((int)(valueFloat * 1000)) % 1000 != 0) {
                valueString = [NSString stringWithFormat:@"%.3f", valueFloat];
            }
            valueFloat *= 1024;
        }

        self.includedData = [NSString stringWithFormat:@"%@%@ / %dGB", valueString, unit, (int)(maxIncludedData/1000)];
        self.percentIncluded = valueFloat / maxIncludedData;
    } else {
        self.includedData = @"";
        self.percentIncluded = 0;
    }

    pattern = @"<div class=\"container-row\">.*<p>Bonus Weekend Data</p>.*<p>([0-9.,]+)([A-Z]+)  </p>.*</div>";
    matches = [self matchData:data withPattern:pattern error:&error];

    if ([matches count] == 2) {
        NSString *value = [[matches objectAtIndex:0] stringByReplacingOccurrencesOfString:@"," withString:@""];
        NSString *unit = [matches objectAtIndex:1];

        float valueFloat = [value floatValue];
        NSString *valueString = [NSString stringWithFormat:@"%d", (int)[value integerValue]];
        if ([unit isEqualToString:@"GB"]) {
            if (((int)(valueFloat * 1000)) % 1000 != 0) {
                valueString = [NSString stringWithFormat:@"%.3f", valueFloat];
            }
            valueFloat *= 1024;
        }

        self.bonusWeekendData = [NSString stringWithFormat:@"%@%@ / %dGB", valueString, unit, (int)(maxBonusWeekendData/1000)];
        self.percentBonusWeekendData = valueFloat / maxBonusWeekendData;
    } else {
        self.bonusWeekendData = @"";
        self.percentBonusWeekendData = 0;
    }

    pattern = @"<p><h2>Error</h2></p><p>(.*)</p>.*<p>([^<]+)</p>";
    matches = [self matchData:data withPattern:pattern error:&error];

    if ([matches count] == 2) {
        NSString *errorString = [NSString stringWithFormat:@"%@!\n\n%@", [matches objectAtIndex:0], [matches objectAtIndex:1]];
        self.error = [NSError errorWithDomain:@"MyBalance" code:100 userInfo:@{NSLocalizedDescriptionKey:errorString}];
    }
    else {
        self.error = error;
    }
}

- (NSArray *)matchData:(NSString *)data withPattern:(NSString *)pattern error:(NSError **)error {
    NSMutableArray *array = nil;

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionDotMatchesLineSeparators error:error];
    NSTextCheckingResult *match = [regex firstMatchInString:data options:NSMatchingReportCompletion range:NSMakeRange(0, [data length])];

    if (match && !*error) {
        array = [[NSMutableArray alloc] initWithCapacity:match.numberOfRanges-1];

        for (NSUInteger i = 1; i < match.numberOfRanges; i++) {
            NSString *group = [data substringWithRange:[match rangeAtIndex:i]];
            NSLog(@"Match %u: %@", (int)i, group);
            [array addObject:group];
        }
    }

    if (*error) {
        NSLog(@"Match error: %@", *error);
    }

    return array;
}

@end
