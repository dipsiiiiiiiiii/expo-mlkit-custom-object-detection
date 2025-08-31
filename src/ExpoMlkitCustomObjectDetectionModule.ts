import { NativeModule, requireNativeModule } from 'expo';

import { ExpoMlkitCustomObjectDetectionModuleEvents, DetectedObject, YoloDetection } from './ExpoMlkitCustomObjectDetection.types';

declare class ExpoMlkitCustomObjectDetectionModule extends NativeModule<ExpoMlkitCustomObjectDetectionModuleEvents> {
  loadCustomModel(modelPath: string): Promise<string>;
  detectObjects(imagePath: string): Promise<DetectedObject[]>;
  detectObjectsWithCustomModel(imagePath: string): Promise<DetectedObject[]>;
  loadYoloModel(modelPath: string): Promise<string>;
  detectObjectsWithYolo(imagePath: string, confidenceThreshold?: number): Promise<YoloDetection[]>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoMlkitCustomObjectDetectionModule>('ExpoMlkitCustomObjectDetection');
