//
//  VirtualObjectNode.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 1/16/25.
//

import SceneKit

class VirtualObjectNode: SCNNode {

    enum VirtualObjectType {
        case nuclearPowerPlant
        case chernobylPowerPlant
    }

    init(_ type: VirtualObjectType = .nuclearPowerPlant) {
        super.init()
        
        var scale = 1.0
        switch type {
        case .nuclearPowerPlant:
            loadUsdz(name: "Nuclear_Powerplant_Low-poly")
            scale = 0.5
        case .chernobylPowerPlant:
            loadUsdz(name: "Chernobyl_Nuclear_Power_Plant_Detailed")
        }
        self.scale = SCNVector3(scale, scale, scale)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func react() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        SCNTransaction.completionBlock = {
            SCNTransaction.animationDuration = 0.15
            self.opacity = 1.0
        }
        self.opacity = 0.5
        SCNTransaction.commit()
    }
}
