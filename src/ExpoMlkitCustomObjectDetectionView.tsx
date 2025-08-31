import { requireNativeView } from 'expo';
import * as React from 'react';

import { ExpoMlkitCustomObjectDetectionViewProps } from './ExpoMlkitCustomObjectDetection.types';

const NativeView: React.ComponentType<ExpoMlkitCustomObjectDetectionViewProps> =
  requireNativeView('ExpoMlkitCustomObjectDetection');

export default function ExpoMlkitCustomObjectDetectionView(props: ExpoMlkitCustomObjectDetectionViewProps) {
  return <NativeView {...props} />;
}
