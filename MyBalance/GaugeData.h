//
//  GaugeData.h
//  MyBalance
//
//  Created by Tommy Sparber on 19/01/2016.
//  Copyright © 2016 Tommy Sparber. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GaugeData : NSObject
@property (strong, nonatomic) NSString *label;
@property (strong, nonatomic) NSString *value;
@property (nonatomic) float gaugeValue;
@end
