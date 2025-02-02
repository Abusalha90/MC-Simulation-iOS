//
//  criticality.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 11/12/2022.
//


import Foundation
import Surge

var histories = 10.0

class Criticality_Sim:ObservableObject{
    
    @Published var showResultsView: Bool = false
    @Published var simulationRun = [SimulationRun(type: "Test", tallyResults: [Tally]())]
    @Published var runTime: Double = 0.0
    @Published var isRunning: Bool = false
    @Published var isImpliciteCapture: Bool = true
    @Published var animationEnabled = false
    @Published var animating = false
    @Published var animatingSpeed = 0.1
    @Published var energyGroups = 2
    
    @Published var initialSource = 0 {
        didSet{
            loadDistribution()
        }
    }
    @Published var particle: neutron = neutron(r: Position(z: 50), w: 1.0, g: .group0)
    @Published var particleHistory : [neutron] = [neutron(r: Position(z: 50), w: 1.0, g: .group0)]
    
    @Published var history = 500.0{
        didSet{
            histories = history
        }
    }
    @Published var cycles = 100
    @Published var currentCycle = 0
    @Published var KeffText = 0.9999
    var ForceStop = false
    
    @Published var inactiveC = 10
    lazy var activeC = cycles - inactiveC
    
    @Published var Keff_CyclesAvg = [Double]()
    @Published var Keff_Cycles1 = [Double]()
    @Published var Keff_Cycles2 = [Double]()
    @Published var Keff_Cycles3 = [Double]()
    
    var Keff_CyclesToMeasure = [Double]()
    var Keff = 0.99
    var M_factor = 1.0
    lazy var bank_N = history
    lazy var pre_bank_N = history
    
    var cyclesTallies = [CycleTallies]() // all active cycles + all regions + all fluxes
    @Published var cycleTallies = CycleTallies(surface: [[fluxTally]](), cell: [[fluxTally]]()) // all regions + all Surfaces + all fluxes
    
    var wLow = 0.01
    var wSurvive = 0.02
    @Published var animateRussianRollete:Bool = false
    @Published var killParticle:Bool = false
    //   geometry
    @Published var regionsView = [Region]()
    @Published var surfacesView = [Surface]()

    var regions = [Region]()
    var surfaces = [Surface]()

    var leftBoundary : Double = 0.0 //{return regions.sorted(by: {$0.xLeft < $1.xLeft}).first!.xLeft}
    
    var slabBoundaries : [Double] { // [0,10,90,100]
        var boundaries = [leftBoundary]
        let arr = regions.map {$0.thickness}
        arr.enumerated().forEach { i,thick in
            let pre = boundaries[i]
            boundaries.append(pre + thick)
        }
        return boundaries
    }
    var rightBoundary : Double {return slabBoundaries.last!}
    
    //    var slabTotWidth : Double {return rightBoundary - leftBoundary} // 100
    //    lazy var regBoundaries = slabBonundaries.dropFirst() // [10,90,100]
    //    lazy var regionsThick = { // [10,80,10]
    //        var arr = self.slabBonundaries()
    //        return zip(arr, arr.dropFirst()).map { abs($1 - $0) }
    //    }
    //    var numOfCells = 10
    //    lazy var cells = Array(repeating: 10.0, count: self.numOfCells)
    //    lazy var cellsImp = Array(repeating: 1, count: self.numOfCells)
    
    
    var simulationLog = [String]()
    var totalInteraction = 0
    var keff_collision_Est = 0.0
    var keff_absobrbtion_Est = 0.0
    var keff_TrackLength_Est = 0.0
    
    @Published var fissionDistrDraw = [Double:[neutron]]()
    var cyclsFissnSource = [FissionSourceDistr]()
    var bankedFissionSource = [neutron]()
    var init_distribution = Array(repeating: neutron(r:Position(z: 50)), count: Int(10))

    
    init(){
        regions = [
            Region(id: 0, material: .Reflector, xLeft: 0, thickness: 10, data: [Xs]()),
            Region(id: 1, material: .Fuel, xLeft: 10, thickness: 10, data: [Xs]()),
            Region(id: 2, material: .Fuel, xLeft: 20, thickness: 10, data: [Xs]()),
            Region(id: 3, material: .Fuel, xLeft: 30, thickness: 10, data: [Xs]()),
            Region(id: 4, material: .Fuel, xLeft: 40, thickness: 10, data: [Xs]()),
            Region(id: 5, material: .Fuel, xLeft: 50, thickness: 10, data: [Xs]()),
            Region(id: 6, material: .Fuel, xLeft: 60, thickness: 10, data: [Xs]()),
            Region(id: 7, material: .Fuel, xLeft: 70, thickness: 10, data: [Xs]()),
            Region(id: 8, material: .Fuel, xLeft: 80, thickness: 10, data: [Xs]()),
            Region(id: 9, material: .Reflector, xLeft: 90, thickness: 10, data: [Xs]())
        ]
        surfaces.removeAll()
        regions.forEach { i in
            let surface = Surface(id: Double(i.id), x: i.xLeft)
            surfaces.append(surface)
            if let lastID = regions.last?.id, lastID == i.id{
                surfaces.append(Surface(id: Double(lastID+1), x: i.xRight))
            }
        }
                
        loadData()
        loadDistribution()
    }
    
   
}
