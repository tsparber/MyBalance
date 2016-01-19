//
//  DataLoader.h
//  MyBalance
//
//  Created by Tommy Sparber on 9/01/2016.
//  Copyright © 2016 Tommy Sparber. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GaugeData.h"

@class DataLoader;

@protocol DataLoaderDelegate <NSObject>
- (void)dataDidChange:(DataLoader *)dataLoader withError:(NSError *)error;
@end

@interface DataLoader : NSObject
@property (nonatomic, weak) id<DataLoaderDelegate> delegate;
@property (nonatomic, strong) NSMutableArray<GaugeData *> *data;
@property (nonatomic, strong) GaugeData *importantData;

- (void)refresh;
@end
