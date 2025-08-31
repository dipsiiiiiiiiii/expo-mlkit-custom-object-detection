// Reexport the native module. On web, it will be resolved to ExpoMlkitCustomObjectDetectionModule.web.ts
// and on native platforms to ExpoMlkitCustomObjectDetectionModule.ts
export { default } from './ExpoMlkitCustomObjectDetectionModule';
export { default as ExpoMlkitCustomObjectDetectionView } from './ExpoMlkitCustomObjectDetectionView';
export * from  './ExpoMlkitCustomObjectDetection.types';
