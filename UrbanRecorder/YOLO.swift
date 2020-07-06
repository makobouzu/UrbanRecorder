//
//  YOLO.swift
//  UrbanRecorder
//
//  Created by Makoto Amano on 2020/06/14.
//  Copyright © 2020 Makoto Amano. All rights reserved.
//

import Foundation
import UIKit
import CoreML

class YOLO {
    // YOLO2 input is 608x608
    public static let inputWidth = 608
    public static let inputHeight = 608
    public static let maxBoundingBoxes = 10
    
    // Tweak these values to get more or fewer predictions.
    let confidenceThreshold: Float = 0.5
    let iouThreshold: Float = 0.6
    
    struct Prediction {
        let classIndex: Int
        let score: Float
        let rect: CGRect
    }
    
    let model = yolo()
    
    public init() { }
    
    public func predict(image: CVPixelBuffer) throws -> [Prediction] {
        if let output = try? model.prediction(input__0: image) {
            return computeBoundingBoxes(features: output.output__0)
        } else {
            return []
        }
    }
    
    public func computeBoundingBoxes(features: MLMultiArray) -> [Prediction] {
        //    assert(features.count == 125*13*13)
        assert(features.count == 425*19*19)
        
        var predictions = [Prediction]()
        
        let blockSize: Float = 32
        let gridHeight = 19
        let gridWidth = 19
        let boxesPerCell = 5;
        let numClasses = 80
        let featurePointer = UnsafeMutablePointer<Double>(OpaquePointer(features.dataPointer))
        let channelStride = features.strides[0].intValue
        let yStride = features.strides[1].intValue
        let xStride = features.strides[2].intValue
        
        func offset(_ channel: Int, _ x: Int, _ y: Int) -> Int {
            return channel*channelStride + y*yStride + x*xStride
        }
        
        for cy in 0..<gridHeight {
            for cx in 0..<gridWidth {
                for b in 0..<boxesPerCell {
                    let channel = b*(numClasses + 5)
                    let tx = Float(featurePointer[offset(channel    , cx, cy)])
                    let ty = Float(featurePointer[offset(channel + 1, cx, cy)])
                    let tw = Float(featurePointer[offset(channel + 2, cx, cy)])
                    let th = Float(featurePointer[offset(channel + 3, cx, cy)])
                    let tc = Float(featurePointer[offset(channel + 4, cx, cy)])
                    let x = (Float(cx) + sigmoid(tx)) * blockSize
                    let y = (Float(cy) + sigmoid(ty)) * blockSize
                    let w = exp(tw) * anchors[2*b    ] * blockSize
                    let h = exp(th) * anchors[2*b + 1] * blockSize
                    let confidence = sigmoid(tc)
                    
                    var classes = [Float](repeating: 0, count: numClasses)
                    for c in 0..<numClasses {
                        classes[c] = Float(featurePointer[offset(channel + 5 + c, cx, cy)])
                    }
                    classes = softmax(classes)
                    
                    let (detectedClass, bestClassScore) = classes.argmax()
                    let confidenceInClass = bestClassScore * confidence
                    if confidenceInClass > confidenceThreshold {
                        let rect = CGRect(x: CGFloat(x - w/2), y: CGFloat(y - h/2),
                                          width: CGFloat(w), height: CGFloat(h))
                        
                        let prediction = Prediction(classIndex: detectedClass,
                                                    score: confidenceInClass,
                                                    rect: rect)
                        predictions.append(prediction)
                    }
                }
            }
        }
        
        return nonMaxSuppression(boxes: predictions, limit: YOLO.maxBoundingBoxes, threshold: iouThreshold)
    }
}

