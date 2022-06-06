// @flow
import { NativeModules, NativeEventEmitter } from 'react-native'

const isTurboModuleEnabled = global.__turboModuleProxy != null;

const PerformanceStatsNativeModule = isTurboModuleEnabled ?
  require("./NativePerformanceStats").default :
  NativeModules.PerformanceStats;

// export default PerformanceStatsNativeModule;

export default {
  start: () => PerformanceStatsNativeModule.start(),
  stop: () => PerformanceStatsNativeModule.stop(),
  addListener: (listenerCallback) => {
    const eventEmitter = new NativeEventEmitter(PerformanceStatsNativeModule);
    return eventEmitter.addListener("performanceStatsUpdate", listenerCallback);
  }
};
