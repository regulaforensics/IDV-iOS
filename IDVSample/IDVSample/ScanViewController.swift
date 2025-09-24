//
//  ScanViewController.swift
//  Example
//
//  Created by Serge Rylko on 28.01.25.
//

import UIKit
import AVKit

protocol ScanViewControllerDelegate: AnyObject {
  func didDetectQRCode(controller: ScanViewController, code: String)
  func didReceiveScanError(controller: ScanViewController, error: ScanError)
}

enum ScanError: Error {
  case unsupportedDevice
}

class ScanViewController: UIViewController {

  private lazy var captureSession = AVCaptureSession()
  private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
    let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer.frame = view.safeAreaLayoutGuide.layoutFrame
    previewLayer.videoGravity = .resizeAspectFill
    return previewLayer
  }()

  var delegate: ScanViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = UIColor.black

    guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
    let videoInput: AVCaptureDeviceInput

    do {
      videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
    } catch {
      return
    }

    if captureSession.canAddInput(videoInput) {
      captureSession.addInput(videoInput)
    } else {
      failed()
      return
    }

    let metadataOutput = AVCaptureMetadataOutput()

    if captureSession.canAddOutput(metadataOutput) {
      captureSession.addOutput(metadataOutput)

      metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
      metadataOutput.metadataObjectTypes = [.qr]
    } else {
      failed()
      return
    }

    previewLayer.masksToBounds = true
    view.layer.addSublayer(previewLayer)

    DispatchQueue.global(qos: .userInteractive).async {
      self.captureSession.startRunning()
    }
  }

  func failed() {
    let alertController = UIAlertController(title: "Scanning process can not be started",
                                            message: "The device doesn't support scanning./n Please use a device with a camera.",
                                            preferredStyle: .alert)
    let actionOK = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
      guard let self else { return }
      self.navigationController?.popViewController(animated: false)
      self.delegate?.didReceiveScanError(controller: self, error: .unsupportedDevice)
    }
    alertController.addAction(actionOK)
    present(alertController, animated: true)
    captureSession.stopRunning()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    if !captureSession.isRunning {
      DispatchQueue.global(qos: .userInteractive).async {
        self.captureSession.startRunning()
      }
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    if captureSession.isRunning {
      captureSession.stopRunning()
    }
  }

  private func found(QRcode: String) {
    print(QRcode)
    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    navigationController?.popViewController(animated: false)
    delegate?.didDetectQRCode(controller: self, code: QRcode)
  }

  override var prefersStatusBarHidden: Bool {
    return true
  }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .portrait
  }
}

extension ScanViewController: AVCaptureMetadataOutputObjectsDelegate {

  func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
    captureSession.stopRunning()

    if let metadataObject = metadataObjects.first {
      guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
      guard let stringValue = readableObject.stringValue else { return }

      found(QRcode: stringValue)
    }

    dismiss(animated: true)
  }
}
