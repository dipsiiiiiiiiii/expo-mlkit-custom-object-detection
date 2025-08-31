import { NativeModule, requireNativeModule } from 'expo';

import { ExpoMlkitCustomObjectDetectionModuleEvents, DetectedObject } from './ExpoMlkitCustomObjectDetection.types';

declare class ExpoMlkitCustomObjectDetectionModule extends NativeModule<ExpoMlkitCustomObjectDetectionModuleEvents> {
  detectObjects(imagePath: string): Promise<DetectedObject[]>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoMlkitCustomObjectDetectionModule>('ExpoMlkitCustomObjectDetection');
