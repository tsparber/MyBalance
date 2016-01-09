//
//  DataLoaderBoost.h
//  MyBalance
//
//  Created by Tommy Sparber on 9/01/2016.
//  Copyright © 2016 Tommy Sparber. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataLoader.h"

@interface DataLoaderBoost : DataLoader

@property (strong, nonatomic) NSString *expires;
@property (strong, nonatomic) NSString *includedData;
@property (strong, nonatomic) NSString *bonusWeekendData;
@property (nonatomic) float percentExpires;
@property (nonatomic) float percentIncluded;
@property (nonatomic) float percentBonusWeekendData;

@end
