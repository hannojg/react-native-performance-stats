package nl.skillnation.perfstats;


import android.os.Debug;
import android.os.Handler;
import android.util.Log;

import androidx.annotation.Nullable;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.modules.debug.FpsDebugFrameCallback;

// Most important impl details from: https://github.com/facebook/react-native/blob/main/ReactAndroid/src/main/java/com/facebook/react/devsupport/FpsView.java
public class PerformanceStatsImpl {
    public static final String NAME = "PerformanceStats";

    private static final int UPDATE_INTERVAL_MS = 500;

    private final FpsDebugFrameCallback mFrameCallback;
    private final StatsMonitorRunnable mStatsMonitorRunnable;
    private final ReactContext reactContext;
    private Handler handler;

    public PerformanceStatsImpl(ReactContext context) {
        mFrameCallback = new FpsDebugFrameCallback(context);
        mStatsMonitorRunnable = new StatsMonitorRunnable();
        reactContext = context;
    }

    public void start() {
        handler = new Handler();
        mFrameCallback.reset();
        mFrameCallback.start();
        mStatsMonitorRunnable.start();
    }

    public void stop() {
        handler = null;
        mFrameCallback.stop();
        mStatsMonitorRunnable.stop();
    }

    private void setCurrentStats(double uiFPS, double jsFPS, int framesDropped, int shutters, long usedRam) {
        WritableMap state = Arguments.createMap();
        state.putDouble("uiFps", uiFPS);
        state.putDouble("jsFps", jsFPS);
        state.putInt("framesDropped", framesDropped);
        state.putInt("shutters", shutters);
        state.putDouble("usedRam", usedRam);

        sendEvent(state);
    }

    private void sendEvent(@Nullable Object data) {
        if (reactContext == null) {
            return;
        }

        if (!reactContext.hasActiveReactInstance()) {
            return;
        }
        reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit("performanceStatsUpdate", data);
    }


    /** Timer that runs every UPDATE_INTERVAL_MS ms and updates the currently displayed FPS and resource usages. */
    private class StatsMonitorRunnable implements Runnable {

        private boolean mShouldStop = false;
        private int mTotalFramesDropped = 0;
        private int mTotal4PlusFrameStutters = 0;

        @Override
        public void run() {
            if (mShouldStop) {
                return;
            }
            mTotalFramesDropped += mFrameCallback.getExpectedNumFrames() - mFrameCallback.getNumFrames();
            mTotal4PlusFrameStutters += mFrameCallback.get4PlusFrameStutters();
            setCurrentStats(
                    mFrameCallback.getFPS(),
                    mFrameCallback.getJSFPS(),
                    mTotalFramesDropped,
                    mTotal4PlusFrameStutters,
                    getUsedRam()
            );
            mFrameCallback.reset();

            // TODO: not sure if we need to run that on a view
            handler.postDelayed(this, UPDATE_INTERVAL_MS);
        }

        public void start() {
            mShouldStop = false;
            handler.post(this);
        }

        public void stop() {
            mShouldStop = true;
        }

        // https://stackoverflow.com/a/19267315/3668241
        private long getUsedRam() {
            // get heap
            final Runtime runtime = Runtime.getRuntime();
            final long usedMemInMB= (runtime.totalMemory() - runtime.freeMemory()) / 1048576L;
            // get native
            long nativeHeapSize = Debug.getNativeHeapSize();
            long nativeHeapFreeSize = Debug.getNativeHeapFreeSize();
            long usedNativeMemInMB = (nativeHeapSize - nativeHeapFreeSize) / 1048576L;

            return usedNativeMemInMB + usedMemInMB;
        }
    }
}
