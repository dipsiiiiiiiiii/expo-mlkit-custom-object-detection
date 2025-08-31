import ExpoModulesCore
import MLKitObjectDetection
import MLKitVision
import UIKit

public class ExpoMlkitCustomObjectDetectionModule: Module {
  private lazy var objectDetector: ObjectDetector = {
    let options = ObjectDetectorOptions()
    options.detectorMode = .singleImage
    options.shouldEnableMultipleObjects = true
    options.shouldEnableClassification = true
    return ObjectDetector.objectDetector(options: options)
  }()

  public func definition() -> ModuleDefinition {
    Name("ExpoMlkitCustomObjectDetection")

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
