// @flow
import { NativeModules } from 'react-native'

const isTurboModuleEnabled = global.__turboModuleProxy != null;

const calculator = isTurboModuleEnabled ?
  require("./NativePerformanceStats").default :
  NativeModules.Calculator;

export default calculator;
