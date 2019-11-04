//
//  ViewController.swift
//  SimpleCustomCamera
//
//  Created by manuAir on 28.10.19.
//  Copyright © 2019 ghostthinker. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate{
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        // save video to camera roll
        if error == nil {
            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
        }
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    //session
    var session: AVCaptureSession!
    var videoOutput = AVCaptureMovieFileOutput()
    var backRecording: Bool = true
    
    //switch
    @IBOutlet weak var toggleSwitchButton: UIButton!
    
    //timer
    var timeMin = 0
    var timeSec = 0
    weak var timer: Timer?
    @IBOutlet weak var labelTimer: UILabel!
    
    //flash
    var flashOn = false
    @IBOutlet weak var toggleFlashButton: UIButton!
    
    //previewView
    @IBOutlet var previewView: UIView!
    
    //system sound id
    let systemSoundBegin: SystemSoundID = 1113
    let systemSoundEnd: SystemSoundID = 1114

    
    override func viewDidLoad() {
        super.viewDidLoad()
        toggleTorch(on: flashOn)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // if your presenting this vc yourLabel.txt will show 00:00
        labelTimer.text = String(format: "%02d:%02d", timeMin, timeSec)
    }
    
    // resets both vars back to 0 and when the timer starts again it will start at 0
    func resetTimerToZero(){
        timeSec = 0
        timeMin = 0
        stopTimer()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        resetTimerToZero()
        self.session.stopRunning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let vc = self.storyboard?.instantiateViewController(withIdentifier: SimpleCameraUI) as! ViewController
        self.present(vc, animated: true, completion: nil)
        session = AVCaptureSession()
        session?.sessionPreset = .high
        setupLivePreview(backRecording: backRecording)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if let connection =  self.videoPreviewLayer.connection  {
            
            let currentDevice: UIDevice = UIDevice.current
            let orientation: UIDeviceOrientation = currentDevice.orientation
            let previewLayerConnection : AVCaptureConnection = connection
            
            if previewLayerConnection.isVideoOrientationSupported {
                switch (orientation) {
                case .portrait: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait); break
                    
                case .landscapeRight: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft); break
                    
                case .landscapeLeft: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight); break
                    
                case .portraitUpsideDown: updatePreviewLayer(layer: previewLayerConnection, orientation: .portraitUpsideDown); break
                    
                default: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait); break
                }
            }
        }
    }
    
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        
        layer.videoOrientation = orientation
        
        self.videoPreviewLayer.frame = self.view.bounds
        
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                self.videoPreviewLayer.frame = self.previewView.bounds
            }
        }
    }
    
    fileprivate func initPreviewLayer() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        videoPreviewLayer.videoGravity = .resizeAspectFill
        previewView.layer.addSublayer(videoPreviewLayer)
        DispatchQueue.global(qos: .userInitiated).async { //[weak self] in
            self.session.startRunning()
            DispatchQueue.main.async {
                self.videoPreviewLayer.frame = self.previewView.bounds
            }
        }
    }
    
    func setupLivePreview(backRecording: Bool) {
        
        //init mircrophone device and input
        guard let microphone = AVCaptureDevice.default(for: AVMediaType.audio)
            else {
                print("Unable to access microphone!")
                return
        }
        let audio = try? AVCaptureDeviceInput(device: microphone)
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
            else {
                print("Unable to access back camera!")
                return
        }
        let input = try? AVCaptureDeviceInput(device: backCamera)
        
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
            else {
                print("Unable to access front camera!")
                return
        }
        let frontInput = try? AVCaptureDeviceInput(device: frontCamera)
        
        if session.inputs.count != 0 {
            session.inputs.forEach { (input) in
                session.removeInput(input)
            }
        }
        if backRecording {
            //init backCamera input with microphone
            if session.canAddInput(input!) && session.canAddInput(audio!) {
                session.addInput(input!)
                session.addInput(audio!)
            }
        } else {
            //init frontCamera input with microphone
            if session.canAddInput(frontInput!) && session.canAddInput(audio!) {
                session.addInput(frontInput!)
                session.addInput(audio!)
            }
        }
        
        initPreviewLayer()
    }
    
    // MARK:- recordButton
    @IBAction fileprivate func recordButtonTapped(_ sender: UIButton) {
        if !videoOutput.isRecording {
            //TODO: Do something with start and stoptime
            startTimer()
            let startTime = startRecording()
            print(startTime)
            toggleSwitchButton.isHidden = true
            
            // to play sound
            AudioServicesPlaySystemSound(systemSoundBegin)
            print("system sound played")
            
        } else {
            resetTimerToZero()
            let timeNow = String(format: "%02d:%02d", timeMin, timeSec)
            labelTimer.text = timeNow
            
            toggleSwitchButton.isHidden = false
            
            let stopTime = stopRecording()
            print(stopTime)
            
            // to play sound
            AudioServicesPlaySystemSound(systemSoundEnd)
            print("system sound played")
        }
    }
    
    func startRecording() -> Double {
        //define paths for media
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("output.mov")
        print(fileUrl)
        //remove possible items at path
        try? FileManager.default.removeItem(at: fileUrl)
        videoOutput = AVCaptureMovieFileOutput()
        session.addOutput(videoOutput)
        
        //set video recording orientation
        if let videoConnection = videoOutput.connection(with: .video) {
            let newOrientation: AVCaptureVideoOrientation
            switch UIDevice.current.orientation {
            case .portrait:
                newOrientation = .portrait
            case .portraitUpsideDown:
                newOrientation = .portraitUpsideDown
            case .landscapeLeft:
                newOrientation = .landscapeRight
            case .landscapeRight:
                newOrientation = .landscapeLeft
            default :
                newOrientation = .portrait
            }
            videoConnection.videoOrientation = newOrientation
        }
        videoOutput.startRecording(to: fileUrl, recordingDelegate: self as AVCaptureFileOutputRecordingDelegate)
        print("started video recording")
        return NSDate().timeIntervalSince1970
    }
    
    
    func stopRecording() -> Double {
        videoOutput.stopRecording()
        print("stopped video capture")
        return NSDate().timeIntervalSince1970
    }
    
    // MARK:- Timer Functions
    fileprivate func startTimer(){
        
        // if you want the timer to reset to 0 every time the user presses record you can uncomment out either of these 2 lines
        
        timeSec = 0
        timeMin = 0
        
        // If you don't use the 2 lines above then the timer will continue from whatever time it was stopped at
        let timeNow = String(format: "%02d:%02d", timeMin, timeSec)
        labelTimer.text = timeNow
        
        stopTimer() // stop it at it's current time before starting it again
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
    }
    
    @objc fileprivate func timerTick(){
        timeSec += 1
        
        if timeSec == 60{
            timeSec = 0
            timeMin += 1
        }
        
        let timeNow = String(format: "%02d:%02d", timeMin, timeSec)
        
        labelTimer.text = timeNow
    }
    
    // if you need to reset the timer to 0 and yourLabel.text back to 00:00
    func resetTimerAndLabel(){
        
        resetTimerToZero()
        labelTimer.text = String(format: "%02d:%02d", timeMin, timeSec)
    }
    
    // stops the timer at it's current time
    func stopTimer(){
        
        timer?.invalidate()
    }
    
    func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) else { print("device for torch not found"); return }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if on == true {
                    device.torchMode = .on
                } else {
                    device.torchMode = .off
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    
    @IBAction func pressedFlashButton(_ sender: Any) {
        if flashOn == true{
            toggleTorch(on: false)
            toggleFlashButton.setImage(#imageLiteral(resourceName: "Flash Off Icon"), for: .normal)
        }
            
        else {
            toggleTorch(on: true)
            
            toggleFlashButton.setImage(#imageLiteral(resourceName: "Flash On Icon"), for: .normal)
        }
        flashOn = !flashOn
    }
    @IBAction func switchCamera(_ sender: UIButton) {
        
        if backRecording {
            toggleSwitchButton.setImage(#imageLiteral(resourceName: "Rear Camera Icon"), for: .normal)
            toggleFlashButton.isHidden = true
        } else {
            toggleSwitchButton.setImage(#imageLiteral(resourceName: "Front Camera Icon"), for: .normal)
            if toggleFlashButton.isHidden == true {
                toggleFlashButton.isHidden = false
            }
        }
        toggleTorch(on: false)
        toggleFlashButton.setImage(#imageLiteral(resourceName: "Flash Off Icon"), for: .normal)
        //stop session to give new settings
        session.stopRunning()
        backRecording = !backRecording
        setupLivePreview(backRecording: backRecording)
    }
}
