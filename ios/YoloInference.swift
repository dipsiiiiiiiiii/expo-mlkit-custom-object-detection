import Foundation
import TensorFlowLite
import UIKit
import CoreGraphics

class YoloInference {
    private var interpreter: Interpreter?
    private let inputWidth: Int = 640
    private let inputHeight: Int = 640
    private let numClasses: Int = 80
    
    struct Detection {
        let boundingBox: CGRect
        let confidence: Float
        let classId: Int
        let className: String?
    }
    
    init(modelPath: String) throws {
        var options = Interpreter.Options()
        options.threadCount = 2
        interpreter = try Interpreter(modelPath: modelPath, options: options)
        try interpreter?.allocateTensors()
    }
    
    func predict(image: UIImage, confidenceThreshold: Float = 0.5) throws -> [Detection] {
        guard let interpreter = interpreter else {
            throw NSError(domain: "YoloInference", code: -1, userInfo: [NSLocalizedDescriptionKey: "Interpreter not initialized"])
        }
        
        // Preprocess image
        guard let inputData = preprocessImage(image) else {
            throw NSError(domain: "YoloInference", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to preprocess image"])
        }
        
        // Run inference
        try interpreter.copy(inputData, toInputAt: 0)
        try interpreter.invoke()
        
        // Get output
        let outputTensor = try interpreter.output(at: 0)
        let outputData = outputTensor.data
        
        // Post-process results
        return try postprocessOutput(outputData, imageSize: image.size, confidenceThreshold: confidenceThreshold)
    }
    
    private func preprocessImage(_ image: UIImage) -> Data? {
        // Resize image to model input size (640x640)
        guard let resizedImage = image.resized(to: CGSize(width: inputWidth, height: inputHeight)),
              let pixelBuffer = resizedImage.pixelBuffer() else {
            return nil
        }
        
        // Convert to normalized float array (0.0 - 1.0)
        var inputData = Data()
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0)) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
        
        // Convert BGRA to RGB and normalize to 0-1
        for y in 0..<height {
            for x in 0..<width {
                let pixelPtr = baseAddress.advanced(by: y * bytesPerRow + x * 4)
                let pixel = pixelPtr.assumingMemoryBound(to: UInt8.self)
                
                // BGRA format -> RGB, normalized to 0-1
                let r = Float(pixel[2]) / 255.0
                let g = Float(pixel[1]) / 255.0  
                let b = Float(pixel[0]) / 255.0
                
                var rData = r.bitPattern.littleEndian
                var gData = g.bitPattern.littleEndian
                var bData = b.bitPattern.littleEndian
                
                inputData.append(Data(bytes: &rData, count: 4))
                inputData.append(Data(bytes: &gData, count: 4))
                inputData.append(Data(bytes: &bData, count: 4))
            }
        }
        
        return inputData
    }
    
    private func postprocessOutput(_ outputData: Data, imageSize: CGSize, confidenceThreshold: Float) throws -> [Detection] {
        let floatArray = outputData.withUnsafeBytes { buffer in
            Array(buffer.bindMemory(to: Float32.self))
        }
        
        print("YOLO Debug - Output tensor size: \(floatArray.count)")
        print("YOLO Debug - Image size: \(imageSize)")
        
        var detections: [Detection] = []
        
        // YOLOv8/v11 output format: [1, 84, 8400] 
        // 84 = 4(bbox) + 80(classes), 8400 = detection candidates
        let numFeatures = 4 + numClasses // 84
        let numDetections = floatArray.count / numFeatures // 8400
        
        print("YOLO Debug - Features: \(numFeatures), Detections: \(numDetections)")
        
        for i in 0..<numDetections {
            // YOLOv8/v11 tensor layout: [x_center, y_center, width, height, class0_prob, class1_prob, ...]
            // Data is stored as: [all_x_centers, all_y_centers, all_widths, all_heights, all_class0_probs, all_class1_probs, ...]
            
            let x = floatArray[i]                    // x_center for detection i
            let y = floatArray[numDetections + i]    // y_center for detection i  
            let w = floatArray[2 * numDetections + i] // width for detection i
            let h = floatArray[3 * numDetections + i] // height for detection i
            
            // Find best class
            var maxClassScore: Float = 0
            var bestClassId = 0
            for j in 0..<numClasses {
                let classScore = floatArray[(4 + j) * numDetections + i]
                if classScore > maxClassScore {
                    maxClassScore = classScore
                    bestClassId = j
                }
            }
            
            let confidence = maxClassScore
            if confidence > confidenceThreshold {
                print("YOLO Debug - Detection \(i): x=\(x), y=\(y), w=\(w), h=\(h), conf=\(confidence), class=\(bestClassId)")
                
                // Convert from normalized coordinates (0-1) to image coordinates
                let boundingBox = CGRect(
                    x: CGFloat(x - w/2) * imageSize.width,
                    y: CGFloat(y - h/2) * imageSize.height,
                    width: CGFloat(w) * imageSize.width,
                    height: CGFloat(h) * imageSize.height
                )
                
                let detection = Detection(
                    boundingBox: boundingBox,
                    confidence: confidence,
                    classId: bestClassId,
                    className: getClassName(for: bestClassId)
                )
                
                detections.append(detection)
            }
        }
        
        print("YOLO Debug - Total detections before NMS: \(detections.count)")
        
        // Apply Non-Maximum Suppression
        let finalDetections = applyNMS(detections: detections)
        print("YOLO Debug - Final detections after NMS: \(finalDetections.count)")
        
        return finalDetections
    }
    
    private func applyNMS(detections: [Detection], iouThreshold: Float = 0.5) -> [Detection] {
        let sortedDetections = detections.sorted { $0.confidence > $1.confidence }
        var filteredDetections: [Detection] = []
        
        for detection in sortedDetections {
            var shouldKeep = true
            for existingDetection in filteredDetections {
                let iou = calculateIoU(detection.boundingBox, existingDetection.boundingBox)
                if iou > iouThreshold {
                    shouldKeep = false
                    break
                }
            }
            if shouldKeep {
                filteredDetections.append(detection)
            }
        }
        
        return filteredDetections
    }
    
    private func calculateIoU(_ rect1: CGRect, _ rect2: CGRect) -> Float {
        let intersection = rect1.intersection(rect2)
        if intersection.isNull { return 0.0 }
        
        let intersectionArea = intersection.width * intersection.height
        let unionArea = rect1.width * rect1.height + rect2.width * rect2.height - intersectionArea
        
        return Float(intersectionArea / unionArea)
    }
    
    private func getClassName(for classId: Int) -> String? {
        // COCO dataset class names - you can customize this
        let classNames = [
            "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck",
            "boat", "traffic light", "fire hydrant", "stop sign", "parking meter", "bench",
            "bird", "cat", "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra",
            "giraffe", "backpack", "umbrella", "handbag", "tie", "suitcase", "frisbee",
            "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove",
            "skateboard", "surfboard", "tennis racket", "bottle", "wine glass", "cup",
            "fork", "knife", "spoon", "bowl", "banana", "apple", "sandwich", "orange",
            "broccoli", "carrot", "hot dog", "pizza", "donut", "cake", "chair", "couch",
            "potted plant", "bed", "dining table", "toilet", "tv", "laptop", "mouse",
            "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "sink",
            "refrigerator", "book", "clock", "vase", "scissors", "teddy bear", "hair drier",
            "toothbrush"
        ]
        
        return classId < classNames.count ? classNames[classId] : nil
    }
}

// MARK: - UIImage Extensions
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func pixelBuffer() -> CVPixelBuffer? {
        let width = Int(size.width)
        let height = Int(size.height)
        
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0)) }
        
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { return nil }
        
        guard let cgImage = self.cgImage else { return nil }
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        
        return buffer
    }
}