//
//  GaugeData.m
//  MyBalance
//
//  Created by Tommy Sparber on 19/01/2016.
//  Copyright © 2016 Tommy Sparber. All rights reserved.
//

#import "GaugeData.h"

@implementation GaugeData

- (instancetype)init {
    self = [super init];

    if (self) {
        self.label = @"Label";
        self.value = @"";
        self.gaugeValue = 0;
    }

    return self;
}

@end
