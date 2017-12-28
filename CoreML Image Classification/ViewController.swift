//
//  ViewController.swift
//  CoreML Image Classification
//
//  Created by Kristaps Grinbergs on 27/12/2017.
//  Copyright © 2017 Kristaps Grinbergs. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController {
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var objectLabel: UILabel!
  @IBOutlet weak var confidenceLabel: UILabel!
  

  override func viewDidLoad() {
    super.viewDidLoad()
    setupSession()
  }


}


// MARK: - AVCaptureSession
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  func setupSession() {
    guard let device = AVCaptureDevice.default(for: .video) else { return }
    guard let input = try? AVCaptureDeviceInput(device: device) else { return }
    
    let session = AVCaptureSession()
    session.sessionPreset = .hd4K3840x2160
    
    let previewLayer = AVCaptureVideoPreviewLayer(session: session)
    previewLayer.frame = view.frame
    imageView.layer.addSublayer(previewLayer)
    
    let output = AVCaptureVideoDataOutput()
    output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
    session.addOutput(output)
    
    // Sets the input of the AVCaptureSession to the device's camera input
    session.addInput(input)
    // Starts the capture session
    session.startRunning()
  }
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    guard let model = try? VNCoreMLModel(for: VGG16().model) else { return }
    
    let request = VNCoreMLRequest(model: model) { data, error in
      // Checks if the data is in the correct format and assigns it to results
      guard let results = data.results as? [VNClassificationObservation] else { return }
      // Assigns the first result (if it exists) to firstObject
      guard let firstObject = results.first else { return }
      
      if firstObject.confidence * 100 >= 30 {
        DispatchQueue.main.async {
          self.objectLabel.text = firstObject.identifier.capitalized
          self.confidenceLabel.text = String(firstObject.confidence * 100) + "%"
        }
        
      }
    }
    
    try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
  }
}
