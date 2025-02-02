//
//  NeutronModel.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 11/12/2022.
//

import Foundation
import SwiftUI

struct SimulationRun:Identifiable,Codable{
    var id = UUID()
    var type : String
    var date = Date()
    var histories = 0.0
    var batches = 0.0
    var runTime = 0.0
    var totInteractions = 0
    var tallyResults : [Tally]
}

struct Tally:Identifiable,Codable{
    var id = UUID()
    var type = ""
    var mean = 0.0
    var variance = 0.0
    var StandardDeviation = 0.0
    var FOM = 0.0
}

struct CycleTallies:Identifiable{
    var id = UUID()
    var surface: [[fluxTally]]
    var cell: [[fluxTally]]
}

struct neutron{
    var r : Position
    var w : Double = 1.0
    var g : energyGroup = .group0
    var phi : Double = 0.0  // radial angle
    var theta : Double = 0.0  // cos axial angle
}

struct Position{
    var x : Double = 0.0
    var y : Double = 0.0
    var z : Double = 0.0
    var position : CGPoint {
        get {
            return CGPoint(x: z, y: y)
        }
    }
    func position(aZ:Double,aY:Double,origin:CGPoint)->CGPoint{
        return CGPoint(x: origin.x + z*aZ, y: origin.y + y*aY)
    }
}
struct Surface:Identifiable{
    var id:Double
    var geometry:GeometryType = .surface
    var x:Double
    var flux_surface = [0.0,0.0,0.0,0.0]
    var current = [0.0,0.0,0.0,0.0]
    var area = 1.0 * 1.0
    var tallies : [fluxTally]{
        get {
            return [
                
                fluxTally(group: .group0, type: .surfaceAvg, score: flux_surface[0]/(histories*area)),
                fluxTally(group: .group1, type: .surfaceAvg, score: flux_surface[1]/(histories*area)),
                fluxTally(group: .group2, type: .surfaceAvg, score: flux_surface[2]/(histories*area)),
                fluxTally(group: .group3, type: .surfaceAvg, score: flux_surface[3]/(histories*area)),
                
                fluxTally(group: .group0, type: .current, score: (current[0])/(histories*area)),
                fluxTally(group: .group1, type: .current, score: (current[1])/(histories*area)),
                fluxTally(group: .group2, type: .current, score: (current[2])/(histories*area)),
                fluxTally(group: .group3, type: .current, score: (current[3])/(histories*area))

            ]
        }
    }
}

struct Region:Identifiable{
    var id:Int
    var geometry:GeometryType = .cell
    var material:materialType
    var xLeft:Double
    var thickness:Double
    var data:[Xs]
//    var surfaces : [Surface]
    var xRight : Double {
        get {
            return xLeft + thickness
        }
    }
    
    var flux_coll = [0.0,0.0,0.0,0.0]
    var flux_length = [0.0,0.0,0.0,0.0]
    var volume = 1.0 * 1.0 * 10.0
    var tallies : [fluxTally]{
        get {
            
            return [
                fluxTally(group: .group0, type: .collision, score: flux_coll[0]/(histories*volume)),
                fluxTally(group: .group1, type: .collision, score: flux_coll[1]/(histories*volume)),
                fluxTally(group: .group2, type: .collision, score: flux_coll[2]/(histories*volume)),
                fluxTally(group: .group3, type: .collision, score: flux_coll[3]/(histories*volume)),

                fluxTally(group: .group0, type: .length, score: flux_length[0]/(histories*volume)),
                fluxTally(group: .group1, type: .length, score: flux_length[1]/(histories*volume)),
                fluxTally(group: .group2, type: .length, score: flux_length[2]/(histories*volume)),
                fluxTally(group: .group3, type: .length, score: flux_length[3]/(histories*volume)),
            ]
        }
    }
    


}

struct Xs: Identifiable{
    var id : Int
    var type: energyGroup
    var total : Double = 0.0
    var absorb : Double = 0.0
    var scattGroup : Double = 0.0
    
    var v_fission : Double = 0.0
    var v : Double = 0.0
    var X : Double = 0.0
    
    var fission : Double {return v_fission/v}
    var scatt : Double {return total - absorb}
    
}
extension Xs {
    init() {
        self.init(id: 0, type: .group1)
    }
}

struct fluxTally {
    var group:energyGroup
    var type : TallyEst
    var score : Double
}


struct FissionSourceDistr{
    var cycle: Int
    var distribution : [neutron]
}

enum TallyEst:String, Equatable,CaseIterable {
    case collision = "Flux by Collision"
    case length = "Flux by Track Length"
    
    case surfaceAvg = "Flux by Surface Average"
    case current = "Current"
    
    var name: LocalizedStringKey { LocalizedStringKey(rawValue) }
}

enum energyGroup:Int,CaseIterable {
    case group0 = 0
    case group1 = 1
    case group2 = 2
    case group3 = 3
}

enum materialType:String,Equatable, CaseIterable {
    case Fuel = "Fuel"
    case Reflector = "Reflector"
    case Moderator = "Moderator"
//    case Clad = "Clad"
//    case Air = "Air"

    var name: LocalizedStringKey { LocalizedStringKey(rawValue) }
}
enum GeometryType{
    case cell
    case surface
}

enum editMode{
    case add
    case update
    case delete
}


extension Double{
    
    var sinus:Double{
        return sin(self * Double.pi / 180)
    }
    var cosin:Double{
        return cos(self * Double.pi / 180)
    }
    ///acos(2 * Double.random(in: 0...1) - 1) * 180 / Double.pi
    static var randTheta:Double{
        return acos(2*Double.random(in: 0...1) - 1) * 180 / Double.pi
    }
    
    /// 2 * Double.pi * Double.random(in: 0...1)
    static var randPhi:Double{
        return 2*Double.pi*Double.random(in: 0...1) * 180 / Double.pi
    }
    
    /// Random number between 0 and 1
    static var rand:Double{
        return Double.random(in: 0...1)
    }
}

