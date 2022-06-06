package nl.skillnation.perfstats;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactMethod;

import nl.skillnation.perfstats.NativePerformanceTrackerSpec;

public class PerformanceStatsModule extends NativePerformanceTrackerSpec {
    private final PerformanceStatsImpl performanceTracker;

    public PerformanceStatsModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.performanceTracker = new PerformanceTrackerImpl(reactContext);
    }

    @NonNull
    @Override
    public String getName() {
        return PerformanceTrackerImpl.NAME;
    }

    @Override
    @ReactMethod
    public void start() {
        performanceTracker.start();
    }

    @Override
    @ReactMethod
    public void stop() {
        performanceTracker.stop();
    }
}