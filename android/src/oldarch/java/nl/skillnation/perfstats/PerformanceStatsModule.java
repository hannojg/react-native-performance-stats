package nl.skillnation.perfstats;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import nl.skillnation.perfstats.PerformanceStatsImpl;

public class PerformanceStatsModule extends ReactContextBaseJavaModule {
    public PerformanceStatsModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @NonNull
    @Override
    public String getName() {
        return PerformanceStatsImpl.NAME;
    }


    @Override
    public void start() {
        // PerformanceTrackerImpl.start();
    }

    @Override
    public void stop() {
        // PerformanceTrackerImpl.stop();
    }
}