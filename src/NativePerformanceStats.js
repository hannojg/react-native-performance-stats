// @flow
import type { TurboModule } from 'react-native/Libraries/TurboModule/RCTExport';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  start(withCPU?: boolean): void;
  stop(): void;
}
export default (TurboModuleRegistry.get<Spec>(
  'PerformanceStats'
): ?Spec);
