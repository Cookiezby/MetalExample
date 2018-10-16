//
//  MTLTexture+Helper.swift
//  MetalExample
//
//  Created by cookie on 2018/10/17.
//  Copyright © 2018 zhubingyi. All rights reserved.
//

import Foundation
import MetalKit

extension MTLTexture {
    func threadGroupCount() -> MTLSize {
        return MTLSizeMake(8, 8, 1)
    }
    
    func threadGroups() -> MTLSize {
        let groupCount = threadGroupCount()
        return MTLSizeMake(Int(self.width) / groupCount.width, Int(self.height) / groupCount.height, 1)
    }
}

