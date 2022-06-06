package nl.skillnation.perfstats;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactMethod;

public class PerformanceStatsModule extends NativePerformanceStatsSpec {
    private final PerformanceStatsImpl performanceStats;

    public PerformanceStatsModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.performanceStats = new PerformanceStatsImpl(reactContext);
    }

    @NonNull
    @Override
    public String getName() {
        return PerformanceStatsImpl.NAME;
    }

    @Override
    @ReactMethod
    public void start() {
        performanceStats.start();
    }

    @Override
    @ReactMethod
    public void stop() {
        performanceStats.stop();
    }

    @ReactMethod
    public void addListener(String eventName) {
        // Set up any upstream listeners or background tasks as necessary
    }

    @ReactMethod
    public void removeListeners(Integer count) {
        // Remove upstream listeners, stop unnecessary background tasks
    }
}