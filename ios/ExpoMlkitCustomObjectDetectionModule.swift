import ExpoModulesCore
import MLKitObjectDetection
import MLKitObjectDetectionCustom
import MLKitVision
import MLKitCommon
import UIKit

public class ExpoMlkitCustomObjectDetectionModule: Module {
  private lazy var objectDetector: ObjectDetector = {
    let options = ObjectDetectorOptions()
    options.detectorMode = .singleImage
    options.shouldEnableMultipleObjects = true
    options.shouldEnableClassification = true
    return ObjectDetector.objectDetector(options: options)
  }()
  
  private var customObjectDetector: ObjectDetector?

  public func definition() -> ModuleDefinition {
    Name("ExpoMlkitCustomObjectDetection")

    AsyncFunction("loadCustomModel") { (modelPath: String, promise: Promise) in
      do {
        self.customObjectDetector = try self.createCustomObjectDetector(for: modelPath)
        promise.resolve("Model loaded successfully")
      } catch {
        promise.reject("MODEL_LOAD_ERROR", "Failed to load custom model: \(error.localizedDescription)")
      }
    }
    
    AsyncFunction("detectObjectsWithCustomModel") { (imagePath: String, promise: Promise) in
      guard let customDetector = self.customObjectDetector else {
        promise.reject("CUSTOM_MODEL_NOT_LOADED", "Custom model not loaded. Call loadCustomModel first.")
        return
      }
      
      guard let image = self.loadImageFromPath(imagePath) else {
        promise.reject("IMAGE_LOAD_ERROR", "Failed to load image from path: \(imagePath)")
        return
      }
      
      let visionImage = VisionImage(image: image)
      
      customDetector.process(visionImage) { objects, error in
        DispatchQueue.main.async {
          if let error = error {
            promise.reject("DETECTION_ERROR", error.localizedDescription)
            return
          }
          
          let detectedObjects = objects?.map { object in
            var result: [String: Any] = [
              "boundingBox": [
                "left": object.frame.minX,
                "top": object.frame.minY,
                "width": object.frame.width,
                "height": object.frame.height
              ],
              "trackingId": object.trackingID ?? NSNull()
            ]
            
            if !object.labels.isEmpty {
              result["labels"] = object.labels.map { label in
                [
                  "text": label.text,
                  "confidence": label.confidence,
                  "index": label.index
                ]
              }
            }
            
            return result
          } ?? []
          
          promise.resolve(detectedObjects)
        }
      }
    }
    
    AsyncFunction("detectObjects") { (imagePath: String, promise: Promise) in
      guard let image = self.loadImageFromPath(imagePath) else {
        promise.reject("IMAGE_LOAD_ERROR", "Failed to load image from path: \(imagePath)")
        return
      }
      
      let visionImage = VisionImage(image: image)
      
      self.objectDetector.process(visionImage) { objects, error in
        DispatchQueue.main.async {
          if let error = error {
            promise.reject("DETECTION_ERROR", error.localizedDescription)
            return
          }
          
          let detectedObjects = objects?.map { object in
            var result: [String: Any] = [
              "boundingBox": [
                "left": object.frame.minX,
                "top": object.frame.minY,
                "width": object.frame.width,
                "height": object.frame.height
              ],
              "trackingId": object.trackingID ?? NSNull()
            ]
            
            if !object.labels.isEmpty {
              result["labels"] = object.labels.map { label in
                [
                  "text": label.text,
                  "confidence": label.confidence,
                  "index": label.index
                ]
              }
            }
            
            return result
          } ?? []
          
          promise.resolve(detectedObjects)
        }
      }
    }

  }
  
  private func createCustomObjectDetector(for modelPath: String) throws -> ObjectDetector {
    let finalModelPath: String
    
    // Handle HTTP URLs - download to temp file
    if modelPath.hasPrefix("http://") || modelPath.hasPrefix("https://") {
      guard let url = URL(string: modelPath),
            let modelData = try? Data(contentsOf: url) else {
        throw NSError(domain: "ModelDownloadError", code: 500, 
                      userInfo: [NSLocalizedDescriptionKey: "Failed to download model from URL: \(modelPath)"])
      }
      
      // Save to temporary file
      let tempDir = FileManager.default.temporaryDirectory
      let tempFile = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("tflite")
      try modelData.write(to: tempFile)
      finalModelPath = tempFile.path
    }
    // Handle absolute paths
    else if modelPath.hasPrefix("/") {
      finalModelPath = modelPath
    } 
    // Handle resource names (try bundle first, then documents)
    else {
      if let bundlePath = Bundle.main.path(forResource: modelPath, ofType: "tflite") {
        finalModelPath = bundlePath
      } else {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelFile = documentsPath.appendingPathComponent("\(modelPath).tflite")
        if FileManager.default.fileExists(atPath: modelFile.path) {
          finalModelPath = modelFile.path
        } else {
          throw NSError(domain: "ModelNotFound", code: 404, 
                        userInfo: [NSLocalizedDescriptionKey: "Model file not found: \(modelPath)"])
        }
      }
    }
    
    let localModel = LocalModel(path: finalModelPath)
    let options = CustomObjectDetectorOptions(localModel: localModel)
    options.detectorMode = ObjectDetectorMode.singleImage
    options.shouldEnableMultipleObjects = true
    options.shouldEnableClassification = true
    options.classificationConfidenceThreshold = NSNumber(value: 0.5)
    options.maxPerObjectLabelCount = 3
    
    return ObjectDetector.objectDetector(options: options)
  }
  
  private func loadImageFromPath(_ path: String) -> UIImage? {
    if path.hasPrefix("http://") || path.hasPrefix("https://") {
      guard let url = URL(string: path),
            let data = try? Data(contentsOf: url) else { return nil }
      return UIImage(data: data)
    } else if path.hasPrefix("file://") {
      let url = URL(string: path)
      guard let filePath = url?.path else { return nil }
      return UIImage(contentsOfFile: filePath)
    } else if path.hasPrefix("/") {
      return UIImage(contentsOfFile: path)
    } else {
      return UIImage(named: path)
    }
  }
}
