#import "PerformanceStats.h"

// Thanks to this guard, we won't import this header when we build for the old architecture.
#ifdef RCT_NEW_ARCH_ENABLED
#import "RNPerformanceStatsSpec.h"
#endif

@implementation PerformanceStats

RCT_EXPORT_MODULE(PerformanceStats)

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[ @"performanceStatsUpdate" ];
}

RCT_REMAP_METHOD(start, withCpu:(NSInteger*)withCpu)
{
    [self sendEventWithName:@"performanceStatsUpdate" body:@{@"jsFps": @60, @"uiFps": @120}];
}

RCT_EXPORT_METHOD(stop)
{
    
}

// Thanks to this guard, we won't compile this code when we build for the old architecture.
#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativePerformanceStatsSpecJSI>(params);
}
#endif

@end
