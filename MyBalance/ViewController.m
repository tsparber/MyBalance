//
//  ViewController.m
//  MyBalance
//
//  Created by Tommy Sparber on 9/01/2016.
//  Copyright © 2016 Tommy Sparber. All rights reserved.
//

#import "ViewController.h"
#import "DataLoaderBoost.h"

@import SafariServices;

@interface ViewController () <DataLoaderDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;

@property (weak, nonatomic) IBOutlet UILabel *includedDataLabel;
@property (weak, nonatomic) IBOutlet UILabel *bonusWeekendDataLabel;
@property (weak, nonatomic) IBOutlet UILabel *expiresLabel;

@property (weak, nonatomic) IBOutlet UIProgressView *includedDataProgress;
@property (weak, nonatomic) IBOutlet UIProgressView *bonusWeekendDataProgress;
@property (weak, nonatomic) IBOutlet UIProgressView *expiresProgress;

@property (strong, nonatomic) DataLoaderBoost *dataLoader;
@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"viewWillAppear");
    [self refresh: nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    self.dataLoader = [[DataLoaderBoost alloc] init];
    self.dataLoader.delegate = self;

    [self.includedDataLabel setText:@"?"];
    [self.bonusWeekendDataLabel setText:@"?"];
    [self.expiresLabel setText:@"?"];
    [self setEnabled:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)refresh:(id)sender {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.dataLoader refresh];
    self.refreshButton.enabled = NO;
}

- (IBAction)showHomepage:(id)sender {
    SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:@"http://care.boost.com.au"]];
    safariViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
    safariViewController.modalTransitionStyle =UIModalTransitionStyleCoverVertical;
    [self presentViewController:safariViewController animated:YES completion:nil];
}

- (void) setEnabled:(BOOL)state {
    for (UIView *view in self.view.subviews) {
        if ([view isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)view;
            [label setEnabled:state];

        } else if ([view isKindOfClass:[UIProgressView class]]) {
            UIProgressView *progressView = (UIProgressView *)view;

            if (!state) {
                [progressView setProgress:1];
            }
        }
    }
}

#pragma mark DataLoader
- (void)dataDidChange:(DataLoader *)dataLoader withError:(NSError *)error {
    NSLog(@"dataDidChange");

    [self setEnabled:YES];

    self.includedDataLabel.text = self.dataLoader.includedData;
    [self.includedDataProgress setProgress:self.dataLoader.percentIncluded animated:YES];

    self.bonusWeekendDataLabel.text = self.dataLoader.bonusWeekendData;
    [self.bonusWeekendDataProgress setProgress:self.dataLoader.percentBonusWeekendData animated:YES];

    self.expiresLabel.text = self.dataLoader.expires;
    [self.expiresProgress setProgress:self.dataLoader.percentExpires animated:YES];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.refreshButton.enabled = YES;

    if (error) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Refresh data" message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];

        [self presentViewController:alertController animated:YES completion:nil];
    }
}

@end
