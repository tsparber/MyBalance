//
//  GaugeTableViewCell.h
//  MyBalance
//
//  Created by Tommy Sparber on 14/01/2016.
//  Copyright © 2016 Tommy Sparber. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GaugeTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UILabel *value;
@property (weak, nonatomic) IBOutlet UIProgressView *gauge;
@end
