//
//  GaugeTableViewCell.m
//  MyBalance
//
//  Created by Tommy Sparber on 14/01/2016.
//  Copyright © 2016 Tommy Sparber. All rights reserved.
//

#import "GaugeTableViewCell.h"

@implementation GaugeTableViewCell

- (void)awakeFromNib {
    // Initialization code
    self.label.text = @"Label";
    self.value.text = @"";
    self.gauge.progress = 0;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
