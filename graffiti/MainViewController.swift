//
//  MainViewController.swift
//  graffiti
//
//  Created by Philippe Kimura-Thollander on 9/10/16.
//  Copyright © 2016 Philippe Kimura-Thollander. All rights reserved.
//

import UIKit
import Masonry
import jot
import AVFoundation


class MainViewController: UIViewController, JotViewControllerDelegate {
    
    //camera stream variables
    let captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    var captureDevice : AVCaptureDevice?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let drawViewController = DrawViewController()
        drawViewController.delegate = self
       
        
        captureSession.sessionPreset = AVCaptureSessionPresetLow
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices! {
            // Make sure this particular device supports video
            if ((device as AnyObject).hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if((device as AnyObject).position == AVCaptureDevicePosition.back) {
                    captureDevice = device as? AVCaptureDevice
                    if captureDevice != nil {
                        beginSession()
                    }
                }
            }
        }
        
        //add drawing view
        self.addChildViewController(drawViewController)
        self.view.addSubview(drawViewController.view)
        drawViewController.didMove(toParentViewController: self)
        drawViewController.view.frame = self.view.frame
    }
    
    func configureDevice() {
    
        if let device = captureDevice {
            
            var finalFormat = AVCaptureDeviceFormat()
            var maxFps: Double = 0
            for vFormat in device.formats
            {
                var ranges      = (vFormat as AnyObject).videoSupportedFrameRateRanges as!  [AVFrameRateRange]
                let frameRates  = ranges[0]
                if frameRates.maxFrameRate >= maxFps && frameRates.maxFrameRate <= 60
                {
                    maxFps = frameRates.maxFrameRate
                    finalFormat = vFormat as! AVCaptureDeviceFormat
                }
            }
            
            do {
                try device.lockForConfiguration()
            } catch {
                print("error locking phone")
            }
            device.activeFormat = finalFormat
            device.focusMode = .continuousAutoFocus
            device.unlockForConfiguration()
        }
    }
    
    func takeScreenshot() -> UIImage {
        let layer = UIApplication.shared.keyWindow!.layer
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
        
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    func beginSession() {
        configureDevice()
        
        let err : NSError? = nil
        do {
            try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
            captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        } catch {
            print(err?.localizedDescription ?? "error")
        }
        if err != nil {
            print("error: \(err?.localizedDescription)")
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.addSublayer(previewLayer!)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer?.frame = self.view.layer.frame
        captureSession.startRunning()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
