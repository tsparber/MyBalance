//
//  ViewController.m
//  MyBalance
//
//  Created by Tommy Sparber on 9/01/2016.
//  Copyright © 2016 Tommy Sparber. All rights reserved.
//

#import "ViewController.h"
#import "GaugeTableViewCell.h"
#import "DataLoaderBoost.h"

@import SafariServices;

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, DataLoaderDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;

@property (weak, nonatomic) IBOutlet UITableView *table;

@property (strong, nonatomic) DataLoader *dataLoader;
@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self refresh: nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    self.dataLoader = [[DataLoaderBoost alloc] init];
    self.dataLoader.delegate = self;

    self.table.delegate = self;
    self.table.dataSource = self;
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
    [self showURL:@"http://care.boost.com.au"];
}

- (IBAction)showGithub:(id)sender {
    [self showURL:@"https://github.com/tsparber/MyBalance"];
}

- (void)showURL:(NSString *)url {
    SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:url]];
    safariViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
    safariViewController.modalTransitionStyle =UIModalTransitionStyleCoverVertical;
    safariViewController.view.tintColor = self.view.tintColor;
    [self presentViewController:safariViewController animated:YES completion:nil];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)[self.dataLoader.data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GaugeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"gaugeCell" forIndexPath:indexPath];
    GaugeData *gaugeData = [self.dataLoader.data objectAtIndex:(NSUInteger)indexPath.row];

    cell.label.text = gaugeData.label;
    cell.value.text = gaugeData.value;
    [cell.gauge setProgress:gaugeData.gaugeValue animated:YES];

    return cell;
}

#pragma mark DataLoader

- (void)dataDidChange:(DataLoader *)dataLoader withError:(NSError *)error {
    NSLog(@"dataDidChange");

    [self.table reloadData];

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
