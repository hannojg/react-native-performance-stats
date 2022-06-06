declare module "react-native-performance-stats" {
    import { EmitterSubscription } from "react-native";

    type PerformanceStats = {
        jsFps: number;
        uiFps: number;
        shutter?: number;
        framesDropped?: number;
        usedCpu: number;
        usedRam: number;
    }

    type PerformanceStatsModule = {
        start: (withCPU?: boolean) => void;
        stop: () => void;
        addListener: (listener: (stats: PerformanceStats) => unknown) => EmitterSubscription;
    }

    export = PerformanceStatsModule;
}