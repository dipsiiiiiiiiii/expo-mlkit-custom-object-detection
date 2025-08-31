import { registerWebModule, NativeModule } from 'expo';

import { ExpoMlkitCustomObjectDetectionModuleEvents } from './ExpoMlkitCustomObjectDetection.types';

class ExpoMlkitCustomObjectDetectionModule extends NativeModule<ExpoMlkitCustomObjectDetectionModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(ExpoMlkitCustomObjectDetectionModule, 'ExpoMlkitCustomObjectDetectionModule');
