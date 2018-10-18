//
//  MetalCameraViewController.swift
//  MetalExample
//
//  Created by cookie on 2018/10/18.
//  Copyright © 2018 zhubingyi. All rights reserved.
//

import Foundation
import UIKit
import MetalKit
import AVFoundation

class MetalCameraView: MTKView {
    var commandQueue: MTLCommandQueue
    var textureCache: CVMetalTextureCache?
    var computerPipelineState: MTLComputePipelineState

    var vertexBuffer: MTLBuffer!
    var renderPassDescriptor: MTLRenderPassDescriptor?
    
    var pixelBuffer: CVPixelBuffer? {
        didSet {
            DispatchQueue.main.async {
                self.setNeedsDisplay()
            }
        }
    }
    
    init(frame frameRect: CGRect) {
        let device = MTLCreateSystemDefaultDevice()!
        let lib = device.makeDefaultLibrary()!
        commandQueue = device.makeCommandQueue()!
    
        let computeFunction = lib.makeFunction(name: "doNothing")!
        computerPipelineState = try! device.makeComputePipelineState(function: computeFunction)
        
        var textCache: CVMetalTextureCache?
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textCache) != kCVReturnSuccess {
            fatalError("Unable to allocate texture cache.")
        } else {
            self.textureCache = textCache
        }
        
        super.init(frame: frameRect, device: device)
        self.device = device
        self.framebufferOnly = false
        self.autoResizeDrawable = false
        self.contentMode = .scaleAspectFit
        self.enableSetNeedsDisplay = true
        self.isPaused = true
        self.contentScaleFactor = UIScreen.main.nativeScale
        self.drawableSize = CGSize(width: 720, height: 1280)
    }
    
    override func draw(_ rect: CGRect) {
        self.render()
    }
    
    private func render() {
        guard let pixelBuffer = pixelBuffer else { return }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        var cvTextureOut: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache!, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &cvTextureOut)
        guard let cvTexture = cvTextureOut, let inputTexture = CVMetalTextureGetTexture(cvTexture) else {
            print("failed to create metal texture")
            return
        }
        
        guard let drawable: CAMetalDrawable = self.currentDrawable else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
        
        commandEncoder?.setComputePipelineState(computerPipelineState)
        commandEncoder?.setTexture(inputTexture, index: 0)
        commandEncoder?.setTexture(drawable.texture, index: 1)
        
        commandEncoder?.dispatchThreadgroups(inputTexture.threadGroups(), threadsPerThreadgroup: inputTexture.threadGroupCount())
        commandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
    
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MetalCameraViewController: UIViewController {
    var captureInput: AVCaptureDeviceInput!
    var captureSession: AVCaptureSession!
    var curDevice: AVCaptureDevice!
    var captureOutput: AVCaptureVideoDataOutput!
    
    lazy var metalView: MetalCameraView = {
        let view = MetalCameraView(frame: self.view.bounds)
        return view
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(metalView)
        
        AVCaptureDevice.requestAccess(for: .video) { (granted) in
            guard granted else {
                print("request camear failed")
                return
            }
        }
        
        guard let device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: .video, position: .front) else { return }
        curDevice = device
        
        do {
            captureInput = try AVCaptureDeviceInput(device: curDevice)
        } catch {
            print("input failed")
        }
        
        //init session
        captureSession = AVCaptureSession()
        captureSession.addInput(captureInput)
        captureSession.sessionPreset = .hd1280x720
        
        //set audio output
        let videoOutputQueue = DispatchQueue(label: "VideoOutput")
        captureOutput = AVCaptureVideoDataOutput()
        captureOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
        captureOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA]
        captureOutput.alwaysDiscardsLateVideoFrames = true
        
        //add output
        guard captureSession.canAddOutput(captureOutput) else { return }
        captureSession.addOutput(captureOutput)
        captureSession.startRunning()
        
        if let captureConnection = captureOutput.connection(with: .video) {
            captureConnection.videoOrientation = .portrait
            captureConnection.isVideoMirrored = true
        }
        metalView.isPaused = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MetalCameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard output == captureOutput else { return }
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            metalView.pixelBuffer = pixelBuffer
        }
    }
}
