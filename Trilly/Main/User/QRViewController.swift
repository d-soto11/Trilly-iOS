//
//  QRViewController.swift
//  Trilly
//
//  Created by Daniel Soto on 10/26/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit
import AVFoundation
import Modals3A
import MBProgressHUD

class QRViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    
    @IBOutlet weak var videoContainer: UIView!
    
    public class func readQR(_ parent: UIViewController) {
        let qr = UIStoryboard(name: "User", bundle: nil).instantiateViewController(withIdentifier: "QR") as! QRViewController
        parent.show(qr, sender: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video as the media type parameter.
        let captureDevice = AVCaptureDevice.default(for: .video)
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            
            // Initialize the captureSession object.
            captureSession = AVCaptureSession()
            
            // Set the input device on the capture session.
            captureSession?.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            videoContainer.layer.addSublayer(videoPreviewLayer!)
            
            qrCodeFrameView = UIView()
            qrCodeFrameView!.bordered(color: Trilly.UI.mainColor, width: CGFloat(10.0))
            videoContainer.addSubview(qrCodeFrameView!)
            // Start video capture.
            captureSession?.startRunning()
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            UIView.animate(withDuration: 0.25, animations: {
                self.qrCodeFrameView?.frame = barCodeObject!.bounds
            })
            
            if metadataObj.stringValue != nil {
                captureSession?.stopRunning()
                MBProgressHUD.showAdded(to: self.view, animated: true)
                Organization.withQR(qr: metadataObj.stringValue ?? "nothing", callback: { (org) in
                    UIView.animate(withDuration: 0.25, animations: {
                        self.qrCodeFrameView?.frame = CGRect.zero
                    })
                    MBProgressHUD.hide(for: self.view, animated: true)
                    if org == nil {
                        Alert3A.show(withTitle: "QR Inválido", body: "No se encontró ninguna organización asociada a este QR", accpetTitle: "Ok", confirmation: {
                            self.captureSession?.startRunning()
                        })
                    } else {
                        User.current!.organization = org!
                        User.current!.save()
                        self.dismiss(animated: true, completion: nil)
                    }
                    
                })
            }
        }
    }
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
