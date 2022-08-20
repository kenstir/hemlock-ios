/// Vision framework code courtesy of
/// https://www.raywenderlich.com/12663654-vision-framework-tutorial-for-ios-scanning-barcodes
///
/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import Vision
import AVFoundation
import os.log

class ScanBarcodeViewController: UIViewController {

    let log = OSLog(subsystem: Bundle.appIdentifier, category: "ScanBarcode")
    
    //MARK: - Properties
    
    var barcodeScannedHandler: ((_ barcode: String) -> Void)?
    var captureSession = AVCaptureSession()

    lazy var detectBarcodeRequest = VNDetectBarcodesRequest { request, error in
        guard error == nil else {
            self.showAlert(title: "Error", message: error?.localizedDescription ?? "error")
            return
        }
        self.processClassification(request)
    }

    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCameraLiveView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }

    //MARK: - Functions
    
    private func setupCameraLiveView() {
        captureSession.sessionPreset = .hd1280x720
        
        let videoDevice = AVCaptureDevice
            .default(.builtInWideAngleCamera, for: .video, position: .back)

        guard
            let device = videoDevice,
            let videoDeviceInput = try? AVCaptureDeviceInput(device: device),
            captureSession.canAddInput(videoDeviceInput) else {
            showAlert(
                title: "Cannot Find Camera",
                message: "There seems to be a problem with the camera on your device.")
            return
        }

        captureSession.addInput(videoDeviceInput)
        
        let captureOutput = AVCaptureVideoDataOutput()
        captureOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        captureSession.addOutput(captureOutput)
        
        configurePreviewLayer()
        
        // TODO: Run session
        captureSession.startRunning()
    }

    //MARK: - Vision
    func processClassification(_ request: VNRequest) {
        guard let barcodes = request.results else { return }
        DispatchQueue.main.async { [self] in
            if captureSession.isRunning {
                view.layer.sublayers?.removeSubrange(1...)
                
                for barcode in barcodes {
                    guard
                        let b = barcode as? VNBarcodeObservation,
                        let value = b.payloadStringValue
                    else { return }
                    os_log("[scan] confidence %.2f symbology %@ len %d value %@", b.confidence, format(b), value.count, value)
                    guard b.confidence > 0.8 else { return }

                    // UPC-A is recognized as EAN-13 and a leading 0 is added; remove it.
                    // See also: https://stackoverflow.com/questions/22767584/ios7-barcode-scanner-api-adds-a-zero-to-upca-barcode-format
                    if b.symbology == .ean13 && value.hasPrefix("0") {
                        let s = String(value.dropFirst())
                        barcodeScannedHandler?(s)
                    } else {
                        barcodeScannedHandler?(value)
                    }

                    // navigate back
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    private func format(_ barcode: VNBarcodeObservation) -> String {
        switch(barcode.symbology) {
        case .ean13: return "EAN-13"
        case .ean8: return "EAN-8"
        case .upce: return "UPC-E"
        default: return "other"
        }
    }
}

//MARK: - AVCaptureDelegation
extension ScanBarcodeViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let imageRequestHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .right)
        
        do {
            try imageRequestHandler.perform([detectBarcodeRequest])
        } catch {
            print(error)
        }
    }
}

extension ScanBarcodeViewController {
    private func configurePreviewLayer() {
        let cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer.videoGravity = .resizeAspectFill
        cameraPreviewLayer.connection?.videoOrientation = .portrait
        cameraPreviewLayer.frame = view.frame
        view.layer.insertSublayer(cameraPreviewLayer, at: 0)
    }
}
