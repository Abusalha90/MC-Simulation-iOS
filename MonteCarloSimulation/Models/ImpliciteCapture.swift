//
//  ImpliciteCapture.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 22/11/2022.
//

import Foundation
import Surge

class ImpliciteCapture_simu_data:ObservableObject{
    
    @Published var showResultsView: Bool = false
    @Published var simulationRun = [SimulationRun(type: "Test", tallyResults: [Tally()])]
    @Published var runTime: Double = 0.0
    @Published var isRunning: Bool = false
    @Published var isImpliciteCapture: Bool = false{
        didSet{
            if !isImpliciteCapture {
                isSplitting = isImpliciteCapture
            }
        }
    }
    @Published var isSplitting: Bool = false{
        didSet{
            if isSplitting {
                isImpliciteCapture = isSplitting
            }
        }
    }
    
    @Published var batches = 100.0
    @Published var histories = 1000.0
    
    //   case A
    @Published var segma_Sctr = 0.7
    @Published var segma_Abs = 0.3
    var segma_tot : Double{
        return segma_Abs + segma_Sctr
    }
    @Published var widthTot = 10 // slab width
    
    @Published var wLow = 0.001
    @Published var wSurvive = 0.002
    init(){
        loadResults()
    }
    
    var bankedNeutrons = [neutron]()
    var cellImp1 = 1.0
    var cellImp2 = 4.0
    var x_cell_Interface = 5.0
    
    var numOfCells = 2
    var dx : Double {
        let numb = Double(widthTot)/Double(numOfCells)
        let rounded = Double(round(10 * numb) / 10)
        
        return rounded // slab interval thickness
    }
    var cellsRegion = [5,10]
    var cellsImp = [1,4]
    
    
    var transmisions = 0.0
    var captured = 0.0
    var reflected = 0.0
    
    var batchArrTransmisions = [Double]()
    var batchArrCaptured = [Double]()
    var batchArrReflected = [Double]()
    
    var totalInteraction = 0
    @Published var currentBatch = 0
    func resetValues(){
        transmisions = 0
        captured = 0
        reflected = 0
        
        batchArrTransmisions = [Double]()
        batchArrCaptured = [Double]()
        batchArrReflected = [Double]()
        
        totalInteraction = 0
    }
    
    func run(){
        print("start running")
        resetValues()
        isRunning.toggle()
        DispatchQueue.global(qos: .userInitiated).async {
            self.startRun()
        }
    }
    
    func startRun(){
        print("batch: ")
        let startTime = DispatchTime.now().uptimeNanoseconds
        for i in 0...Int(batches-1){
            DispatchQueue.main.async {
                self.currentBatch = i+1
            }
            transmisions = 0; reflected = 0 ;captured = 0
            historyLoop(batch:i)
        }
        let endTime = DispatchTime.now().uptimeNanoseconds
        DispatchQueue.main.async {
            self.runTime = Double(endTime - startTime)/1_000_000_000
            print("finished running with runTime = \(self.runTime)")
            self.isRunning.toggle()
            self.getResults()
        }
    }
    
    
    func historyLoop(batch i:Int){
        for _ in 0...Int(histories-1){
            
            interactionLoop(n_position: 0.0, gammaRand: 1.0, weight: 1.0)
            
            while bankedNeutrons.count > 1,let neutron = bankedNeutrons.first {
                bankedNeutrons.remove(at: 0)
                
                let random = Double.random(in: -1...1)
                interactionLoop(n_position: neutron.r.z, gammaRand: random, weight: neutron.w)
                
            }
        }
        batchArrTransmisions.append(transmisions/histories)
        batchArrReflected.append(reflected/histories)
        batchArrCaptured.append(captured/histories)
        
    }
    
    func interactionLoop(n_position:Double,gammaRand:Double,weight:Double){
        
        var x_init = n_position // x_init = 0 if not specified in the function
        var x = x_init
        var rand = gammaRand
        var w = weight
        //            # initially fixed direction towards the slap
        
        var interaction = true
        while interaction {
            totalInteraction += 1
            
            let lamda = Double.random(in: 0...1)
            let s = -log(lamda)/segma_tot
            x = x_init + s*rand
            
            if x<0 { //# reflection
                reflected += w
                interaction = false
                
            } else if x>10{// penetration leakage
                transmisions += w
                interaction = false
            } else {
                let normRand = Double.random(in: 0...1)
                let absorbtionProb = segma_Abs/segma_tot
                if isImpliciteCapture{
                    
                    if isSplitting {
                        applySplitting()
                    }
                    
                    captured += w*absorbtionProb
                    w *= segma_Sctr/segma_tot
                    
                    if w<wLow {
                        if normRand<(w/wSurvive){
                            w = wSurvive
                            resumeInteraction()
                        } else {
                            interaction = false
                        }
                    } else {
                        resumeInteraction()
                    }
                    
                    
                }
                
                else if normRand < absorbtionProb{
                    captured += w
                    interaction = false
                } else {
                    resumeInteraction()
                }
            }
            
            func resumeInteraction(){
                interaction = true
                x_init = x
                rand = Double.random(in: -1...1)
            }
            
            func applySplitting(){
                var ratio = 1.0
                var imp_init = cellImp1
                var imp_finl = cellImp2
                
                if x_init < x_cell_Interface , x > x_cell_Interface{
                    imp_init = cellImp1
                    imp_finl = cellImp2
                } else if x_init > x_cell_Interface , x < x_cell_Interface{
                    imp_init = cellImp2
                    imp_finl = cellImp1
                } else {
                    imp_finl = imp_init
                }
                
                ratio = imp_finl/imp_init
                var n = Int(ratio)
                
                if ratio > 1 {
                    let p = ratio - Double(n) // for n+1 split
                    if Double.random(in: 0...1) < p {
                        n  = n+1
                    } else {
                        // 1-p for n split
                    }
                    w = w/ratio

                    let bankedN = Array(repeating: neutron(r: Position(z:x),w: w), count: n-1)
                    bankedNeutrons += bankedN
                    
                } else if ratio < 1{
                    let p = 1 - ratio // apply RR
                    if Double.random(in: 0...1) > p {
                        n = 1
                        w = w/ratio
                    } else {
                        interaction = false
                        // kill N & end simulation
                    }
                } else {
                    // ratio == 1
                    // w remains same
                }
                
                
            }
            
        }
        
    }
    
    
    func getResults(){
        print("=======================================")
        var runType = ""
        if isImpliciteCapture && isSplitting{
            print("MonteCarlo implicit capture & Weight splitting")
            runType = "MonteCarlo implicit capture & Weight splitting"
        } else if isImpliciteCapture{
            runType = "MonteCarlo implicit capture"
            print("implicit capture")
        } else {
            runType = "standard MonteCarlo"
            print("standard MonteCarlo")
        }
        print("totalInteraction")
        print(totalInteraction)
        
        
        let batchMeanCaptured = batchArrCaptured.reduce(0,+)/batches
        let batchMeanTransmisions = batchArrTransmisions.reduce(0,+)/batches
        let batchMeanReflected = batchArrReflected.reduce(0,+)/batches
        
        let reflectedVar = ((pow(batchArrReflected,2) - pow(batchMeanReflected,2))/(batches-1)).reduce(0,+)
        let transmisionVar = ((pow(batchArrTransmisions,2) - pow(batchMeanTransmisions,2))/(batches-1)).reduce(0,+)
        let capturedVar = ((pow(batchArrCaptured,2) - pow(batchMeanCaptured,2))/(batches-1)).reduce(0,+)
        
        let reflectedSTD = reflectedVar.squareRoot()
        let transmisionSTD = transmisionVar.squareRoot()
        let capturedSTD = capturedVar.squareRoot()
        
        let reflectedFOM = 1/(reflectedVar*runTime)
        let transmisionFOM = 1/(transmisionVar*runTime)
        let capturedFOM = 1/(capturedVar*runTime)
        
        let reflectionResults = Tally(type:"Reflection",mean: batchMeanReflected, variance: reflectedVar, StandardDeviation: reflectedSTD, FOM: reflectedFOM)
        let transmissionResults = Tally(type:"Transmission",mean: batchMeanTransmisions, variance: transmisionVar, StandardDeviation: transmisionSTD, FOM: transmisionFOM)
        let captureedResults = Tally(type:"Captured",mean: batchMeanCaptured, variance: capturedVar, StandardDeviation: capturedSTD, FOM: capturedFOM)
        
        let simuResults = SimulationRun(type: runType,histories: histories,batches: batches,runTime: runTime,totInteractions: totalInteraction, tallyResults: [reflectionResults,transmissionResults,captureedResults])
        simulationRun.append(simuResults)
        saveResults()
        showResultsView.toggle()
        print("probability of reflection : \(reflectionResults) , variance : \(reflectedVar) ,StD = \(reflectedSTD) ,FOM \(reflectedFOM)")
        print("probability of transportation : \(batchMeanTransmisions) , variance : \(transmisionVar)  , StD =  \(transmisionSTD) ,FOM \(transmisionFOM)")
        print("probability of absorption :  \(batchMeanCaptured) , variance : \(capturedVar)  , StD = \(capturedSTD), FOM \(capturedFOM)")
        print("=======================================")
    }
    
    func saveResults(){
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(simulationRun) {
            UserDefaults.standard.set(encoded, forKey: "simulationData")
        }
    }
    
    func loadResults(){
        print("loading results")
        if let simulationData = UserDefaults.standard.object(forKey: "simulationData") as? Data {
            
            if let results = try? JSONDecoder().decode([SimulationRun].self, from: simulationData) {
                print("loaded")
                simulationRun = results
            }
        }
    }
}

/*
 probability of reflection : 0.20794000000000004 , variance : 0.013505639999998091 ,StD = 0.011679923204395943
 probability of transportation : 0.00047000000000000037 , variance : 5.090999999999992e-05  , StD =  0.0007171069824248146
 probability of absorption :  0.7915899999999998 , variance : 0.013302190000043401  , StD = 0.011591615743976073
 totalInteraction

 mean of reflection : 0.20986999999999992 variance: 0.000182397070707104, StD = 0.01350544596476192
 FOM : 15317.448235044865
 mean of transportation : 0.0004300000000000001 variance: 6.112121212121219e-07, StD = 0.0007818005635787953
 FOM : 4571011.587988898
 mean of absorbtion : 0.7897000000000002 variance: 0.00018364646464628167, StD = 0.013551622214564634
 FOM : 15213.239711208631
 */

//probability of reflection : 0.21008999999999997 , variance : 0.00020177969696970937 ,StD = 0.014204918055719624
//probability of transportation : 0.00044000000000000023 , variance : 5.115151515151517e-07  , StD =  0.000715202874375622
//probability of absorption :  0.7894700000000001 , variance : 0.0001994233333332417  , StD = 0.01412173266045076

//probability of reflection : 0.20939000000000005 , variance : 0.00020072515151512812 ,StD = 0.01416775040417949
//probability of transportation : 0.00047000000000000037 , variance : 6.55656565656567e-07  , StD =  0.000809726228830811
//probability of absorption :  0.7901399999999995 , variance : 0.00020068727272812747  , StD = 0.01416641354500593

//probability of reflection : 0.20876000000000006 , variance : 0.00018228525252522916 ,StD = 0.013501305585950907
//probability of transportation : 0.00047000000000000026 , variance : 4.73838383838384e-07  , StD =  0.0006883591968139774
//probability of absorption :  0.7907700000000001 , variance : 0.0001831687878787419  , StD = 0.013533986400124019

//probability of reflection : 0.2086099871223108 , variance : 5.4200151625490825e-05 ,StD = 0.007362075225470793
//probability of transportation : 0.0004053361047165694 , variance : 9.970108909552873e-08  , StD =  0.0003157547926723025
//probability of absorption :  0.7909833205732464 , variance : 5.396439355398099e-05  , StD = 0.007346046117060591


