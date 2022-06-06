// @flow
import { NativeModules } from 'react-native'

const isTurboModuleEnabled = global.__turboModuleProxy != null;

const PerformanceStats = isTurboModuleEnabled ?
  require("./NativePerformanceStats").default :
  NativeModules.PerformanceStats;

export default PerformanceStats;
