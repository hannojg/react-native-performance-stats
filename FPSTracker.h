//
//  FPSTracker.h
//  react-native-performance-stats
//
//  Created by Hanno Gödecke on 06.06.22.
//

#ifndef FPSTracker_h
#define FPSTracker_h

@interface FPSTracker : NSObject
    @property (nonatomic, assign, readonly) NSUInteger FPS;
    @property (nonatomic, assign, readonly) NSUInteger maxFPS;
    @property (nonatomic, assign, readonly) NSUInteger minFPS;

    - (void)onTick:(NSTimeInterval)timestamp;
@end

#endif /* FPSTracker_h */
