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
        self.data = [[NSMutableArray alloc] initWithCapacity:4];
        self.importantData = nil;
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
    [self.data removeAllObjects];
    self.importantData = nil;
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
    NSString *pattern = nil;
    NSString *plan = nil;
    NSInteger maxIncludedData = 1000;
    NSInteger maxBonusWeekendData = 500;
    NSInteger maxExpiry = 30;
    NSString *planExpiry = @"";

    // Match error
    pattern = @"<p><h2>Error</h2></p><p>(.*)</p>.*<p>([^<]+)</p>";
    matches = [self matchData:data withPattern:pattern error:&error];

    if ([matches count] == 2) {
        NSString *errorString = [NSString stringWithFormat:@"%@!\n\n%@", [matches objectAtIndex:0], [matches objectAtIndex:1]];
        self.error = [NSError errorWithDomain:@"MyBalance" code:100 userInfo:@{NSLocalizedDescriptionKey:errorString}];
        return;
    }

    // Match plan
    pattern = @"<div class=\"container-row\">.*<p>([A-Z]+)<sup>&reg;</sup></p>.*<p> Expires ([0-9/ :]+)</p>.*</div>";
    matches = [self matchData:data withPattern:pattern error:&error];

    if ([matches count] == 2) {
        plan = [matches objectAtIndex:0];
        NSString *trademark = @"";

        if ([plan isEqualToString:@"UNLTD"]) {
            maxIncludedData = 3000;
            maxBonusWeekendData = 2000;
            trademark = @"®";
        } else if ([plan isEqualToString:@"ULTRA"]) {
            maxIncludedData = 1000;
            maxBonusWeekendData = 500;
            trademark = @"™";
        } else {
            NSString *errorString = [NSString stringWithFormat:@"Plan: %@ unknown!", plan];
            self.error = [NSError errorWithDomain:@"MyBalance" code:100 userInfo:@{NSLocalizedDescriptionKey:errorString}];
            return;
        }

        GaugeData *gaugeData = [self parseExpiry:[matches objectAtIndex:1] maxExpiry:maxExpiry];
        gaugeData.label = [NSString stringWithFormat:@"%@%@ - Expires", plan, trademark];
        planExpiry = gaugeData.value;
        [self.data addObject:gaugeData];
        self.importantData = gaugeData;
    } else {
        self.error = [NSError errorWithDomain:@"MyBalance" code:100 userInfo:@{NSLocalizedDescriptionKey:@"No plan found!"}];
        return;
    }

    // Match included data
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

        GaugeData *gaugeData = [[GaugeData alloc] init];
        gaugeData.label = @"Included Data";
        gaugeData.value = [NSString stringWithFormat:@"%@%@ / %dGB", valueString, unit, (int)(maxIncludedData/1000)];
        gaugeData.gaugeValue = valueFloat / maxIncludedData;
        [self.data addObject:gaugeData];
        self.importantData = gaugeData;

        gaugeData = [self parseExpiry:[matches objectAtIndex:2] maxExpiry:maxExpiry];
        gaugeData.label = @"Included Data - Expires";
        if (![gaugeData.value isEqualToString:planExpiry]) {
            [self.data addObject:gaugeData];
        }
    }

    // Match bonus weekend data
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

        GaugeData *gaugeData = [[GaugeData alloc] init];
        gaugeData.label = @"Bonus Weekend Data";
        gaugeData.value = [NSString stringWithFormat:@"%@%@ / %dGB", valueString, unit, (int)(maxBonusWeekendData/1000)];
        gaugeData.gaugeValue = valueFloat / maxBonusWeekendData;
        [self.data addObject:gaugeData];
        self.importantData = gaugeData;
    }

    self.error = error;
}

- (GaugeData *)parseExpiry:(NSString *)expiry maxExpiry:(NSInteger)maxExpiry {
    GaugeData *gaugeData = [[GaugeData alloc] init];
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"dd/MM/yyyy HH:mm:ss"];

    NSDate *date = [format dateFromString:expiry];
    float timeFromNow = (float)[date timeIntervalSinceNow];
    float daysFromNow = timeFromNow / 60 / 60 / 24;

    gaugeData.value = [NSString stringWithFormat:@"%.1fd / %dd", daysFromNow, (int)maxExpiry];
    gaugeData.gaugeValue = daysFromNow / maxExpiry;

    return gaugeData;
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
