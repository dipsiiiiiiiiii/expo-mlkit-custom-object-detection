import * as React from 'react';

import { ExpoMlkitCustomObjectDetectionViewProps } from './ExpoMlkitCustomObjectDetection.types';

export default function ExpoMlkitCustomObjectDetectionView(props: ExpoMlkitCustomObjectDetectionViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
