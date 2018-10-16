//
//  MPSScaleViewController.swift
//  MetalExample
//
//  Created by cookie on 2018/10/16.
//  Copyright © 2018 zhubingyi. All rights reserved.
//

import Foundation
import UIKit
import MetalPerformanceShaders
import MetalKit

class MPSScaleViewController: MetalViewController {
    private let scaleSize = CGSize(width: 400, height: 400)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mtkView.framebufferOnly = false
        applyScale()
    }
    
    func applyScale() {
        let commandQueue = device.makeCommandQueue()!
        let cgImage = UIImage(named: "gaki")!.cgImage!
        let width = cgImage.width
        let height = cgImage.height

        //shrink to 400 * 400 image
        let scale = CGFloat(min(Double(scaleSize.width) / Double(width), Double(scaleSize.height) / Double(height)))
        var transform = MPSScaleTransform(scaleX: Double(scale), scaleY: Double(scale), translateX: Double(0), translateY: Double(0))
        let commandBuffer1 = commandQueue.makeCommandBuffer()!
        
        let textureLoader = MTKTextureLoader(device: device)
        let srcTexture = try! textureLoader.newTexture(cgImage: cgImage, options: nil)
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: srcTexture.pixelFormat, width: Int(scaleSize.width), height: Int(scaleSize.height), mipmapped: false)
        descriptor.usage = [.shaderRead, .shaderWrite]
        let desTexture = device.makeTexture(descriptor: descriptor)!
        
        let filter = MPSImageLanczosScale(device: device)
        withUnsafePointer(to: &transform) { (transformPtr: UnsafePointer<MPSScaleTransform>) -> () in
            filter.scaleTransform = transformPtr
            filter.encode(commandBuffer: commandBuffer1, sourceTexture: srcTexture, destinationTexture: desTexture)
        }
        commandBuffer1.commit()
        commandBuffer1.waitUntilCompleted()
        
        
        let lib = device.makeDefaultLibrary()!
       
        guard let drawable: CAMetalDrawable = mtkView.currentDrawable else { return }
        
        //draw white background
        let commandBuffer2 = commandQueue.makeCommandBuffer()!
        let computeFunction2 = lib.makeFunction(name: "white")!
        let computePipelineState2 = try! device.makeComputePipelineState(function: computeFunction2)
        let encoder2 = commandBuffer2.makeComputeCommandEncoder()
        encoder2?.setComputePipelineState(computePipelineState2)
        encoder2?.setTexture(drawable.texture, index: 0)
        encoder2?.dispatchThreadgroups(drawable.texture.threadGroups() , threadsPerThreadgroup: drawable.texture.threadGroupCount())
        encoder2?.endEncoding()
    
        //draw image
        let computeFunction3 = lib.makeFunction(name: "doNothing")!
        let computePipelineState3 = try! device.makeComputePipelineState(function: computeFunction3)
        let encoder3 = commandBuffer2.makeComputeCommandEncoder()
        encoder3?.setComputePipelineState(computePipelineState3)
        encoder3?.setTexture(desTexture, index: 0)
        encoder3?.setTexture(drawable.texture, index: 1)
        encoder3?.dispatchThreadgroups(desTexture.threadGroups() , threadsPerThreadgroup: desTexture.threadGroupCount())
        encoder3?.endEncoding()
        commandBuffer2.present(drawable)
        commandBuffer2.commit()
    }
}
