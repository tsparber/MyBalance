//
//  TodayViewController.m
//  MyBalanceWidget
//
//  Created by Tommy Sparber on 10/01/2016.
//  Copyright © 2016 Tommy Sparber. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

#import "DataLoaderBoost.h"

@interface TodayViewController () <NCWidgetProviding, DataLoaderDelegate>
@property (weak, nonatomic) IBOutlet UILabel *dataLabel;
@property (weak, nonatomic) IBOutlet UILabel *dataValue;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@property (strong, nonatomic) DataLoader *dataLoader;

@property (copy, nonatomic) void (^completionHandler)(NCUpdateResult updateResult);
@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    [self setPreferredContentSize:CGSizeMake(0.0, 46.5)];

    self.dataLoader = [[DataLoaderBoost alloc] init];
    self.dataLoader.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

    self.completionHandler = completionHandler;
    [self refresh];
}

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)margins {
    margins.bottom = 8.0;
    return margins;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self refresh];
}

- (void)refresh {
    self.dataLabel.text = @"Loading...";
    self.dataValue.text = @"";
    [self.progressView setProgress:0];
    [self.dataLoader refresh];
}

- (IBAction)openApp:(id)sender {
    NSURL *url = [NSURL URLWithString:@"mybalance://"];
    [self.extensionContext openURL:url completionHandler:nil];
}

#pragma mark DataLoader
- (void)dataDidChange:(DataLoader *)dataLoader withError:(NSError *)error {
    NSLog(@"dataDidChange");

    if (error || self.dataLoader.importantData == nil) {
        self.dataLabel.text = @"Update error!";
        self.dataValue.text = @"";
        [self.progressView setProgress:0];
    } else {
        self.dataLabel.text = self.dataLoader.importantData.label;
        self.dataValue.text = self.dataLoader.importantData.value;
        [self.progressView setProgress:self.dataLoader.importantData.gaugeValue];
    }

    if (self.completionHandler) {
        self.completionHandler(NCUpdateResultNewData);
        self.completionHandler = nil;
    }
}

@end
