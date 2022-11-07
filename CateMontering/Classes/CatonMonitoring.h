//
//  CatonMonitoring.h
//  APP卡顿监测原理分析
//
//  Created by luhua-mac on 2019/6/19.
//  Copyright © 2019 luhua-mac. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CatonMonitoring : NSObject<NSCopying>

+(CatonMonitoring *)singleDeauft;

-(void)startCatonMonitoringTask;
//多长时间为卡顿了 默认为3秒
@property(nonatomic,assign) NSTimeInterval seconds;
//卡顿的回调
@property(nonatomic,copy) void(^CatonMonitorEvent)(void);

@end

NS_ASSUME_NONNULL_END
