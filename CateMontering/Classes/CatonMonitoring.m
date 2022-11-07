//
//  CatonMonitoring.m
//  APP卡顿监测原理分析
//
//  Created by luhua-mac on 2019/6/19.
//  Copyright © 2019 luhua-mac. All rights reserved.
//

#import "CatonMonitoring.h"

@interface CatonMonitoring ()
@property(nonatomic,strong)NSThread  * monitorThread;
/*主线程的监听器*/
@property(nonatomic,assign)CFRunLoopObserverRef observerRef;
/*子线程的定时器*/
@property(nonatomic,assign)CFRunLoopTimerRef  timerRef;
/*间隔多长时间监听*/
@property(nonatomic,assign)NSTimeInterval  timerInvel;
/*最大的时间 也就是超过这个时间就算卡顿*/
@property(nonatomic,assign)NSTimeInterval  maxTimerInvel;
/*开始监听的状态*/
@property(nonatomic,assign,getter=isBegin)BOOL begin;
/*开始监听的时间*/
@property(nonatomic,strong)NSDate * startDate;



@end

@implementation CatonMonitoring

-(void)setSeconds:(NSTimeInterval)seconds{
    _seconds = seconds;
}


static CatonMonitoring  * onstance = nil;

+(CatonMonitoring *)singleDeauft{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        onstance = [[self alloc]init];
        onstance.seconds = 3;
        onstance.monitorThread = [[NSThread alloc]initWithTarget:self selector:@selector(monitorEntry) object:nil];
        [onstance.monitorThread start];
    });
    return onstance;
}
/*防止对象alloc 创建*/
+(instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        onstance = [super allocWithZone:zone];
        onstance.seconds = 3;
    });
    return onstance;
}
/*防止对象copy*/
- (id)copyWithZone:(nullable NSZone *)zone{
    onstance.seconds = 3;
    return onstance;
}
+(void)monitorEntry{
    @autoreleasepool {
        /*保证线程的持久*/
        [[NSRunLoop currentRunLoop] addPort:[NSMachPort port] forMode:NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop]run];
    }
}
-(void)startCatonMonitoringTask{
    /*监听主线程的事件 也就是 beforesources  ---beforewaiting*/
    //1.添加监听器
    [self startCatonMonitoringTask:0.01 MaxTime:_seconds];
    //2.在子线程添加timer 监听
    [self performSelector:@selector(timerEntry) onThread:self.monitorThread withObject:nil waitUntilDone:NO];
    
}
-(void)timerEntry{
    if (self.timerRef) {
        return;
    }
    CFRunLoopTimerContext  context ={
        0,
        (__bridge void *)(self),
        &CFRetain,
        &CFRelease,
        NULL
    };
    self.timerRef = CFRunLoopTimerCreate(CFAllocatorGetDefault(), CFAbsoluteTimeGetCurrent(), _timerInvel, 0, 0, &MoRunLoopTimerCallBack, &context);
    CFRunLoopRef runloop = CFRunLoopGetCurrent();
    CFRunLoopAddTimer(runloop, self.timerRef, kCFRunLoopCommonModes);
    CFRelease(self.timerRef);
    
}

void MoRunLoopTimerCallBack(CFRunLoopTimerRef timer, void *info){
     CatonMonitoring  * monitor = (__bridge CatonMonitoring *)(info);
    if (monitor.isBegin ==YES) {//还在处理
        return;
    }
    NSTimeInterval  diff = [[NSDate date]timeIntervalSinceDate:monitor.startDate];
    if (diff > monitor.maxTimerInvel) {
       // NSLog(@"---app 卡顿了");
        if (onstance.CatonMonitorEvent) {
            onstance.CatonMonitorEvent();
        }
    }else{
       // NSLog(@"---app 正常范围内");
    }
}

-(void)startCatonMonitoringTask:(NSTimeInterval)invel MaxTime:(NSTimeInterval)maxtime{
    _timerInvel = invel;
    _maxTimerInvel = maxtime;
    if (self.observerRef) {
        return;
    }
    CFRunLoopObserverContext  context ={
        0,
        (__bridge void *)(self),
        &CFRetain,
        &CFRelease,
        NULL
    };
    self.observerRef = CFRunLoopObserverCreate(CFAllocatorGetDefault(), kCFRunLoopAllActivities, YES, 0, &MoRunLoopObserverCallBack, &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), self.observerRef, kCFRunLoopCommonModes);
    CFRelease(self.observerRef);
}

void MoRunLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    CatonMonitoring  * monitor = (__bridge CatonMonitoring *)(info);
    switch (activity) {
        case kCFRunLoopEntry:
            NSLog(@"kCFRunLoopEntry");
            break;
        case kCFRunLoopBeforeTimers:
            NSLog(@"kCFRunLoopBeforeTimers");
            break;
        case kCFRunLoopBeforeSources:
            NSLog(@"kCFRunLoopBeforeSources");
            monitor.begin = YES;
            monitor.startDate = [NSDate date];
            break;
        case kCFRunLoopBeforeWaiting:
            NSLog(@"kCFRunLoopBeforeWaiting");
            monitor.begin = NO;
            break;
        case kCFRunLoopAfterWaiting:
            NSLog(@"kCFRunLoopAfterWaiting");
            break;
        case kCFRunLoopExit:
            NSLog(@"kCFRunLoopExit");
            break;
            
        default:
            break;
    }
}


@end
