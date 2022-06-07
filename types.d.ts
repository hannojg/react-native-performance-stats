import { EmitterSubscription } from "react-native";

export type PerformanceStatsData = {
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
    addListener: (listener: (stats: PerformanceStatsData) => unknown) => EmitterSubscription;
}

declare const PerformanceStats: PerformanceStatsModule;
export default PerformanceStats;
