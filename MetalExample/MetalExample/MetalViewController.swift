//
//  MetalViewController.swift
//  MetalExample
//
//  Created by cookie on 2018/10/16.
//  Copyright © 2018 zhubingyi. All rights reserved.
//

import Foundation
import UIKit
import MetalKit

class MetalViewController: UIViewController {
    let device = MTLCreateSystemDefaultDevice()!
    lazy var mtkView: MTKView = {
        let view = MTKView(frame: .zero, device: device)
        return view
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(mtkView)
        let offsetY = UI.naviBarHeight + UI.statusBarHeight
        mtkView.frame = CGRect(x: 0, y: offsetY, width: view.bounds.width, height: view.bounds.height - offsetY)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
