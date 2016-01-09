//
//  ViewController.m
//  MyBalance
//
//  Created by Tommy Sparber on 9/01/2016.
//  Copyright © 2016 Tommy Sparber. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;

@property (weak, nonatomic) IBOutlet UILabel *includedDataLabel;
@property (weak, nonatomic) IBOutlet UILabel *bonusWeekendDataLabel;
@property (weak, nonatomic) IBOutlet UILabel *expiresLabel;

@property (weak, nonatomic) IBOutlet UIProgressView *includedDataProgress;
@property (weak, nonatomic) IBOutlet UIProgressView *bonusWeekendDataProgress;
@property (weak, nonatomic) IBOutlet UIProgressView *expiresProgress;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
