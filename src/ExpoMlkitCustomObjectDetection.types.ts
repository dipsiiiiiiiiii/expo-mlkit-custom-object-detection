import type { StyleProp, ViewStyle } from 'react-native';

export interface DetectedObject {
  boundingBox: {
    left: number;
    top: number;
    width: number;
    height: number;
  };
  trackingId?: number;
  labels?: ObjectLabel[];
}

export interface ObjectLabel {
  text: string;
  confidence: number;
  index: number;
}

export type OnLoadEventPayload = {
  url: string;
};

export type ExpoMlkitCustomObjectDetectionModuleEvents = {
  onChange: (params: ChangeEventPayload) => void;
};

export type ChangeEventPayload = {
  value: string;
};

export type ExpoMlkitCustomObjectDetectionViewProps = {
  url: string;
  onLoad: (event: { nativeEvent: OnLoadEventPayload }) => void;
  style?: StyleProp<ViewStyle>;
};
