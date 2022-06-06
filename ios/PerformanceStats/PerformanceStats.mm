#import "PerformanceStats.h"
#import <mach/mach.h>
#import <React/RCTBridge+Private.h>
#import <React/RCTBridge.h>
#import <React/RCTUIManager.h>

// Thanks to this guard, we won't import this header when we build for the old architecture.
#ifdef RCT_NEW_ARCH_ENABLED
#import "RNPerformanceStatsSpec.h"
#endif

// NOTICE: Mainly copied from here: https://github.com/facebook/react-native/blob/main/React/CoreModules/RCTPerfMonitor.mm


static vm_size_t RCTGetResidentMemorySize(void)
{
  vm_size_t memoryUsageInByte = 0;
  task_vm_info_data_t vmInfo;
  mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
  kern_return_t kernelReturn = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&vmInfo, &count);
  if (kernelReturn == KERN_SUCCESS) {
    memoryUsageInByte = (vm_size_t)vmInfo.phys_footprint;
  }
  return memoryUsageInByte;
}

@implementation PerformanceStats {
    bool _isRunning;
}

@synthesize bridge = _bridge;

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

- (void)updateStats
{
    // View count
    NSDictionary<NSNumber *, UIView *> *views = [_bridge.uiManager valueForKey:@"viewRegistry"];
    NSUInteger viewCount = views.count;
    NSUInteger visibleViewCount = 0;
    for (UIView *view in views.allValues) {
      if (view.window || view.superview.window) {
        visibleViewCount++;
      }
    }
    
    // Memory
    double mem = (double)RCTGetResidentMemorySize() / 1024 / 1024;
    
    [self sendEventWithName:@"performanceStatsUpdate" body:@{
        @"jsFps": @60,
        @"uiFps": @120,
        @"usedRam": [NSNumber numberWithDouble:mem],
        @"viewCount": [NSNumber numberWithUnsignedInteger:viewCount],
        @"visibleViewCount": [NSNumber numberWithUnsignedInteger:visibleViewCount]
    }];
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      __strong __typeof__(weakSelf) strongSelf = weakSelf;
      if (strongSelf && strongSelf->_isRunning) {
        [strongSelf updateStats];
      }
    });
}

RCT_REMAP_METHOD(start, withCpu:(NSInteger*)withCpu)
{
    _isRunning = true;
    [self updateStats];
    
}

RCT_EXPORT_METHOD(stop)
{
    _isRunning = false;
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
