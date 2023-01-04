
//
//  criticality.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 11/12/2022.
//


import Foundation
import Surge

//var history = 5000.0

class Criticalsity_Sim:ObservableObject{
    
    @Published var showResultsView: Bool = false
    @Published var simulationRun = [SimulationRun(type: "Test", tallyResults: [Tally]())]
    @Published var runTime: Double = 0.0
    @Published var isRunning: Bool = false
    @Published var isImpliciteCapture: Bool = true
    @Published var initialSource = 0 {
        didSet{
            loadDistribution()
        }
    }
    @Published var history = 5000.0
    @Published var cycles = 100
    @Published var currentCycle = 0
    @Published var KeffText = 1.0
    var ForceStop = false

    var inactiveC = 10
    lazy var activeC = cycles - inactiveC
    
    @Published var Keff_Cycles = [Double]()
    var Keff_CyclesToMeasure = [Double]()
    var Keff = 0.95
    var M = 1.0
    lazy var bank_W = history
    
    var cyclesTallies = [[[fluxTally]]]() // all active cycles + all regions + all fluxes
    @Published var cycleTallies = [[fluxTally]]() // all regions + all fluxes

    var wLow = 0.001
    var wSurvive = 0.002
    //   geometry
    @Published var regionsView = [Region]()
    
    var regions = [Region]()
    
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
//    var collisionsEst = [Double]()
    
    @Published var fissionDistrDraw = [Int:[neutron]]()
    var cyclsFissnSource = [FissionSourceDistr]()
    var bankedFissionSource = [neutron]()
    
    
    init(){
        regions = [
            Region(id: 0, type: .Reflector, xLeft: 0, thickness: 10, data: [Xs]()),
            Region(id: 1, type: .Fuel, xLeft: 10, thickness: 10, data: [Xs]()),
            Region(id: 2, type: .Fuel, xLeft: 20, thickness: 10, data: [Xs]()),
            Region(id: 3, type: .Fuel, xLeft: 30, thickness: 10, data: [Xs]()),
            Region(id: 4, type: .Fuel, xLeft: 40, thickness: 10, data: [Xs]()),
            Region(id: 5, type: .Fuel, xLeft: 50, thickness: 10, data: [Xs]()),
            Region(id: 6, type: .Fuel, xLeft: 60, thickness: 10, data: [Xs]()),
            Region(id: 7, type: .Fuel, xLeft: 70, thickness: 10, data: [Xs]()),
            Region(id: 8, type: .Fuel, xLeft: 80, thickness: 10, data: [Xs]()),
            Region(id: 9, type: .Reflector, xLeft: 90, thickness: 10, data: [Xs]())
        ]
        loadData()
        loadDistribution()
    }
    
    func run(){
        print("start running")
        totalInteraction = 0
        isRunning.toggle()
        DispatchQueue.global(qos: .userInitiated).async {
            self.startRun()
        }
    }
    var init_distribution = Array(repeating: neutron(r:Position(z: 50)), count: Int(10))

    func loadDistribution(){
        print("load dist")
        init_distribution.removeAll()

        // point source at the center
        if initialSource == 0 {
            init_distribution = Array(repeating: neutron(r:Position(x: 50)), count: Int(history))
        } else {
            Array(0..<Int(history)).forEach{ _ in
                let gamma = 80 * Double.random(in: 0...1) + 10 // normal distribution
                init_distribution.append(neutron(r:Position(x: gamma)))
            }
        }
        
        cyclsFissnSource.removeAll()
        cyclsFissnSource.append(FissionSourceDistr(cycle: 0, distribution: init_distribution))
        bankedFissionSource = init_distribution
        
        let dict = Dictionary(grouping: init_distribution, by: {Int($0.r.x)})
        DispatchQueue.main.async {
            self.fissionDistrDraw = dict
        }
        
        
        
    }
   
    
    func startRun(){
        print("cycle: ")
        let startTime = DispatchTime.now().uptimeNanoseconds
        
        bankedFissionSource.removeAll()
        bank_W = 0
        keff_collision_Est = 0
        
        loadData()
        loadDistribution()

        for i in 0...Int(cycles-1){
            if ForceStop {
                break
            }
            cycleLoop(i)
            let dict = Dictionary(grouping: bankedFissionSource, by: {Int($0.r.x)})
            DispatchQueue.main.async {
                self.currentCycle = i+1
                self.fissionDistrDraw = dict
            }
            
            keff_collision_Est = 0
            bankedFissionSource.removeAll()
            bank_W = 0

            regions.enumerated().forEach { (i,_) in
                regions[i].flux_coll = [0.0,0.0,0.0,0.0]
                regions[i].flux_length = [0.0,0.0,0.0,0.0]
            }
        }
        
        
        let endTime = DispatchTime.now().uptimeNanoseconds
        DispatchQueue.main.async {
            self.runTime = Double(endTime - startTime)/1_000_000_000
            print("finished running with runTime = \(self.runTime)")
            self.isRunning.toggle()
            self.getResults()
        }
    }
    
    
    func cycleLoop(_ i:Int){
        let source = cyclsFissnSource[i]
        source.distribution.enumerated().forEach { h,n in // neutron distribution specturm as a history
            interactionLoop(n:n,cycle: i,history: h)
        }
        
        print("currentCycle \(i)")
        
        var previousN = isImpliciteCapture ? bank_W : Double(bankedFissionSource.count)
        M = history / previousN
//        Keff = Double(bankedFissionSource.count) / history     // old method for Keff
        Keff = keff_collision_Est/history
     
        print("Keff is \(Keff) for cycle: \(i) ,, M \(M), bank_W \(bank_W),, bankedfission \(bankedFissionSource.count)")
//        print("Old Keff is \(oldKeff) for cycle: \(i)")
        
        print("bankedFissionSource \(previousN) ")
        DispatchQueue.main.async {
            self.Keff_Cycles.append(self.Keff)
            self.KeffText = self.Keff
        }
        
        if i >= inactiveC {
            
            let allRegionsTallies = regions.map { $0.tallies }
            DispatchQueue.main.async {
                self.Keff_CyclesToMeasure.append(self.Keff)
                self.cyclesTallies.append(allRegionsTallies)
                self.cycleTallies = allRegionsTallies
            }
            
        }
        
        
        let fixedBankFission = reserveNumberOfHistories(bankedFissionSource)
        let newDistribution = FissionSourceDistr(cycle: i, distribution: fixedBankFission)
        cyclsFissnSource.append(newDistribution)

    }
    
    func interactionLoop(n:neutron,cycle:Int,history:Int){
        var x_init = n.r.x // x_init = 0 if not specified in the function
        var x = x_init
        var gamma = Double.random(in: -1...1) // direction, isotropic point source ,
        var w = n.w
        var group = (n.g == .group1) ? 0 : 1
        var region = getNeutronRegion(r: n.r) // current interaction region
        var xs = region.data[group] // current crosssection group
        var lamda = Double.random(in: 0...1)
        
        var isInteraction = true
        while isInteraction {
            if ForceStop {
                break
            }
            
            
            let s = -log(lamda)/xs.total
            
            let boundary = gamma > 0 ? region.xRight : region.xLeft
            let lg = boundary - x_init
            let lc = s*gamma

            if abs(lc) > abs(lg) {
                x = boundary + (gamma > 0 ? 0.01: -0.01)
                regions[region.id].flux_length[group] += abs(lg*w/10)

                
                if x<=leftBoundary { //# reflection
                    isInteraction = false
                } else if x>=rightBoundary{// penetration leakage
                    isInteraction = false
                } else {
                    // move neutron to boudndary and skip current iteration
                    // reserve direction segma
                    
                    updateParameters(gammaRand: gamma)
                }
                
            } else {
                x = x_init + lc
                keff_collision_Est += w * xs.v_fission/xs.total
                
                if isImpliciteCapture {
                    let rand = Double.random(in: 0...1)
                    let new_n = Int((w * (xs.v_fission/xs.total) * (1/Keff) ) + rand) //  w = 1 for analog MC,
                    if new_n != 0 {
                        bank_W += Double(new_n)
                        let bankedN =  Array(repeating: neutron(r: Position(x:x),g: .group1), count: new_n)
                        bankedFissionSource += bankedN
                    }
                    
                    regions[region.id].flux_coll[group] +=  w/xs.total/10
                    regions[region.id].flux_length[group] += abs((s*w/10))


                    w *= xs.scatt/xs.total

//                    print(w)
                    if w<wLow {
                        gamma = Double.random(in: 0...1)
                        if gamma<(w/wSurvive){
                            w = wSurvive
                            if Double.random(in: 0...1) < xs.scattGroup/xs.total {
                                group += 1 // change cross sections group to thermal
                            }
                            updateParameters(gammaRand: Double.random(in: -1...1))

                            //isInteraction = true
                        } else {
                            isInteraction = false
                        }
                    } else {
                        
                        if Double.random(in: 0...1) < xs.scattGroup/xs.total {
                            group += 1 // change cross sections group to thermal
                        }
                        updateParameters(gammaRand: Double.random(in: -1...1))
                        //isInteraction = true
                    }
                    
                } else {
//                    xs.v_fission = xs.v_fission/Keff
                    
                    let fissionProb = xs.fission/xs.total
                    let absorbtionProb = xs.absorb/xs.total

                    if Double.random(in: 0...1) < absorbtionProb {
                        isInteraction = false
                    }
                    else
                    if Double.random(in: 0...1) < fissionProb {
                        let rand = Double.random(in: 0...1)
                        let newNeutrons = Int((M * xs.v / Keff ) + rand) // analog , w = 1
                        //  Int((w * (xs.v_fission/xs.total) * (1/Keff) ) + gamma)  // non analog
                        //var fissionSpectrum = xs.fisnSpectrum_X // fast fission spectrum = 1
                        //var neutron_group = 0 // fission spectrum is fixed for fast group X_fast=1 , X_thermal = 0
                        let bankedN =  Array(repeating: neutron(r: Position(x:x),g: .group1), count: newNeutrons)
                        bankedFissionSource += bankedN
                        isInteraction = false
                    } else {
                        if Double.random(in: 0...1) < xs.scattGroup/xs.total {
                            group = 1 // change cross sections group to thermal
                        }
                        updateParameters(gammaRand: Double.random(in: -1...1))
                        //isInteraction = true
                    }
                }
            }
        }
        
        func updateParameters(gammaRand:Double){
            totalInteraction += 1
            x_init = x
            gamma = gammaRand
            lamda = Double.random(in: 0...1)
            region = getNeutronRegion(r: Position(x:x)) // update current region
            xs = region.data[group]  // update current cross section data from
//            simulationLog.append("cycle: \(cycle), history # : \(history), n position : \(x),  in region: \(region.type) ")
        }
        
        func getNeutronRegion(r:Position) -> Region{
            
            return regions.filter {
                return r.x >= $0.xLeft && r.x <= $0.xRight
                
            }.first!
        }
        
        func isNeutronInVacuum(x:Double) -> Bool{
            if x<leftBoundary { //# reflection
                
                return true
            } else if x>rightBoundary{// penetration leakage
                
                return true
            } else {
                return false
            }
        }
                
    }
    
    
    func getResults(){
        print("=======================================")
        print("totalInteraction")
        print(totalInteraction)
        guard !ForceStop else {return}
        
        let cycles = Double(activeC)
        print(Keff_CyclesToMeasure.count)
        
        let keffMean = Keff_CyclesToMeasure.reduce(0,+)/cycles
        let keffVar = ((pow(Keff_CyclesToMeasure,2) - pow(keffMean,2))/(cycles-1)).reduce(0,+)
        let keffSTD = keffVar.squareRoot()
        let keffFOM = 1/(keffVar*runTime)
        
        let phi_coll_fast_data = cyclesTallies.map { regionTally in
            return regionTally.map { tallyType in
                return tallyType.first(where: {$0.type == .collision && $0.group == .group0 })!.score
            }
        }
        
        calculateFlux(type: "Phi Collision fast neutrons", data: phi_coll_fast_data)
       
        let phi_coll_therml_data = cyclesTallies.map { regionTally in
            return regionTally.map { tallyType in
                return tallyType.first(where: {$0.type == .collision && $0.group == .group1 })!.score
            }
        }
        calculateFlux(type: "Phi Collision thermal neutrons", data: phi_coll_therml_data)

        let phi_length_fast_data = cyclesTallies.map { regionTally in
            return regionTally.map { tallyType in
                return tallyType.first(where: {$0.type == .length && $0.group == .group0 })!.score
            }
        }
        calculateFlux(type: "Phi Track length Fast neutrons", data: phi_length_fast_data)

        let phi_length_therml_data = cyclesTallies.map { regionTally in
            return regionTally.map { tallyType in
                return tallyType.first(where: {$0.type == .length && $0.group == .group1 })!.score
            }
        }
        calculateFlux(type: "Phi  Track length thermal neutrons", data: phi_length_therml_data)

        let keffResutls = Tally(type:"Keff",mean: keffMean, variance: keffVar, StandardDeviation: keffSTD, FOM: keffFOM)
        
        let simuResults = SimulationRun(type: "Criticality",histories: history,batches: cycles,runTime: runTime,totInteractions: totalInteraction, tallyResults: [keffResutls])
        simulationRun.append(simuResults)
        saveResults()
        showResultsView.toggle()
        
        print("# active cycles : \(activeC) , Keff :  \(keffMean) , variance : \(keffVar)  , StD = \(keffSTD), FOM \(keffFOM)")
        print("=======================================")
    }
    
    func calculateFlux(type:String,data:[[Double]]){
        let V = 10.0 // volume
        
        var meanVal = Array(repeating: 0.0, count: regions.count)
        data.forEach { arr in
            meanVal = Surge.add(meanVal , arr/Double(activeC) )
        }
        
        var variance = Array(repeating: 0.0, count: regions.count)
        var STD = Array(repeating: 0.0, count: regions.count)
        data.forEach { arr in
            let diff = Surge.sub(pow(arr,2), pow(meanVal,2))/Double(activeC-1)
            variance = Surge.add(variance, diff)
        }
        
        variance.enumerated().forEach { i,mean in
            let segmaTot = type.contains("length") ? 1 : regions[i].data[0].total
            variance[i] *= (segmaTot * V)
            // fix variance from original mean
        }

        variance.enumerated().forEach { i,variance in
            let segmaTot =  type.contains("length") ? 1 : regions[i].data[0].total

            STD[i] = variance.squareRoot() / (Double(activeC)*segmaTot*V)
        }

        let FOM = variance.map({1 / ($0*runTime) })

        print("\(type) \n # of active cycles : \(activeC) ,\n phi :  \(meanVal) \n variance : \(variance)  \n StD = \(STD) \n FOM \(FOM)")
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
    func updateRegion(region:Region,mode:editMode){
        if mode == .add{
            regions.append(region)
        } else if mode == .update {
            regions[region.id] = region
        }
        
        fixRegionsBoundaries()
    }

    
    func removeRegion(region:Region){
        if let index = regions.firstIndex(where: {$0.id == region.id}){
            regions.remove(at: index)
        }
        fixRegionsBoundaries()
    }
    
    func fixRegionsBoundaries (){
        var boundaries = slabBoundaries
        boundaries.removeLast()
        boundaries.enumerated().forEach { i,xleft in
            regions[i].xLeft = xleft
        }
        regionsView = regions
    }
    func loadData(){
      
        
        
        let fuelXsFast = Xs(id: 0, type: .group1, total: 0.22, absorb: 0.013, scattGroup: 0.01,v_fission: 0.0065,v: 2.6,X: 1.0)
        let fuelXsFast2 = Xs(id: 1, type: .group2, total: 0.22, absorb: 0.013, scattGroup: 0.02,v_fission: 0.0065,v: 2.6,X: 1.0)
        let fuelXsTherml = Xs(id: 2,type: .group3, total: 0.8, absorb: 0.18, scattGroup: 0.0, v_fission: 0.24, v: 2.4, X: 0.0)
        
        let reflectorXsFast = Xs(id: 0,type: .group1, total: 0.2, absorb: 0.001, scattGroup: 0.015)
        let reflectorXsFast2 = Xs(id: 1,type: .group2, total: 0.2, absorb: 0.001, scattGroup: 0.035)
        let reflectorXsTherml = Xs(id: 2,type: .group3, total: 0.95, absorb: 0.05, scattGroup: 0.0)
        
        let currentRegions = regions
        currentRegions.enumerated().forEach { i,reg in
            if reg.type == .Fuel {
                regions[i].data = [fuelXsFast,fuelXsFast2,fuelXsTherml]
            } else {
                regions[i].data = [reflectorXsFast,reflectorXsFast2,reflectorXsTherml]
            }
        }
        print(regions.map{$0.data.map{$0.fission}})
        
        DispatchQueue.main.async {
            self.regionsView = self.regions
        }
        
    }
    
    func stopSimulation(){
        ForceStop.toggle()
    }
    
    func reserveNumberOfHistories(_ array:[neutron]) -> [neutron]{
        var distr = array
        if isImpliciteCapture {
            distr = distr.map({ n in
                var n = n
                n.w = M
                return n
            })
        } else {
            while distr.count != Int(history){
                if let index = distr.indices.randomElement() {
                    if distr.count > Int(history) {
                        distr.remove(at: index)
                    } else {
                        let val = distr[index]
                        distr.append(val)
                    }
                }
            }
        }
        
        return distr
    }
    
}
