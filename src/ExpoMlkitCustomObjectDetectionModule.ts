import { NativeModule, requireNativeModule } from 'expo';

import { ExpoMlkitCustomObjectDetectionModuleEvents } from './ExpoMlkitCustomObjectDetection.types';

declare class ExpoMlkitCustomObjectDetectionModule extends NativeModule<ExpoMlkitCustomObjectDetectionModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoMlkitCustomObjectDetectionModule>('ExpoMlkitCustomObjectDetection');
