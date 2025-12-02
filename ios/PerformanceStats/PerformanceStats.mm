#import "PerformanceStats.h"
#import "FPSTracker.h"
#import <mach/mach.h>
#import <React/RCTBridge+Private.h>
#import <React/RCTBridge.h>
#import <React/RCTUIManager.h>

// Thanks to this guard, we won't import this header when we build for the old architecture.
#ifdef RCT_NEW_ARCH_ENABLED
#import "RNPerformanceStatsSpec.h"
#endif

// NOTICE: Mainly copied from here: https://github.com/facebook/react-native/blob/main/React/CoreModules/RCTPerfMonitor.mm

#pragma Resource usage methods
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

// https://stackoverflow.com/a/8382889/3668241
float cpu_usage()
{
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads
    
    basic_info = (task_basic_info_t)tinfo;
    
    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0)
        stat_thread += thread_count;
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    
    for (j = 0; j < (int)thread_count; j++)
    {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->user_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
        
    } // for each thread
    
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);
    
    return tot_cpu;
}

#pragma Module implementation

@implementation PerformanceStats {
    bool _isRunning;
    
    FPSTracker *_uiFPSTracker;
    FPSTracker *_jsFPSTracker;
    
    CADisplayLink *_uiDisplayLink;
    CADisplayLink *_jsDisplayLink;
    
    NSInteger* cpuConfigForUpdateStats;
    NSTimer* timerForMonitor;
}

RCT_EXPORT_MODULE(PerformanceStats)

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addObservers];
    }
    return self;
}

- (void)dealloc
{
    [self removeObservers];
    
    if ([self->timerForMonitor isValid]) {
        [self->timerForMonitor invalidate];
    }
}

- (void)addObservers
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(reactNativeWillReload) name:RCTBridgeWillReloadNotification object:nil];
}

- (void)removeObservers
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:RCTBridgeWillReloadNotification object:nil];
}

- (void)reactNativeWillReload
{
    if ([self->timerForMonitor isValid]) {
        [self->timerForMonitor invalidate];
    }
}

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
    NSDictionary<NSNumber *, UIView *> *views = [self.bridge.uiManager valueForKey:@"viewRegistry"];
    NSUInteger viewCount = views.count;
    NSUInteger visibleViewCount = 0;
    for (UIView *view in views.allValues) {
        if (view.window || view.superview.window) {
            visibleViewCount++;
        }
    }
    
    // Memory
    double mem = (double)RCTGetResidentMemorySize() / 1024 / 1024;
    float cpu = 0;
    if (self->cpuConfigForUpdateStats) {
        cpu = cpu_usage();
    }
    
    [self sendEventWithName:@"performanceStatsUpdate" body:@{
        @"jsFps": [NSNumber numberWithUnsignedInteger:_jsFPSTracker.FPS],
        @"uiFps": [NSNumber numberWithUnsignedInteger:_uiFPSTracker.FPS],
        @"usedCpu": [NSNumber numberWithFloat:cpu],
        @"usedRam": [NSNumber numberWithDouble:mem],
        @"viewCount": [NSNumber numberWithUnsignedInteger:viewCount],
        @"visibleViewCount": [NSNumber numberWithUnsignedInteger:visibleViewCount]
    }];
}

- (void)threadUpdate:(CADisplayLink *)displayLink
{
    FPSTracker *tracker = displayLink == _jsDisplayLink ? _jsFPSTracker : _uiFPSTracker;
    [tracker onTick:displayLink.timestamp];
}

RCT_REMAP_METHOD(start, withCpu:(NSInteger*)withCpu)
{
    _isRunning = true;
    _uiFPSTracker= [[FPSTracker alloc] init];
    _jsFPSTracker= [[FPSTracker alloc] init];
    
    self->cpuConfigForUpdateStats = withCpu;
    self->timerForMonitor = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateStats) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self->timerForMonitor forMode:NSDefaultRunLoopMode];
    
    // Get FPS for UI Thread
    _uiDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(threadUpdate:)];
    [_uiDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    // Get FPS for JS thread
    [self.bridge
     dispatchBlock:^{
        self->_jsDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(threadUpdate:)];
        [self->_jsDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
     queue:RCTJSThread];
    
}

RCT_EXPORT_METHOD(stop)
{
    _isRunning = false;
    _jsFPSTracker = nil;
    _uiFPSTracker = nil;
    
    [_uiDisplayLink invalidate];
    [_jsDisplayLink invalidate];
    
    _uiDisplayLink = nil;
    _jsDisplayLink = nil;
    
    if ([self->timerForMonitor isValid]) {
        [self->timerForMonitor invalidate];
    }
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
