//
//  CriticalityFunc.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 08/01/2023.
//

import Foundation
import Surge

extension Criticality_Sim{
    func run(){
        print("start running")
        totalInteraction = 0
        isRunning.toggle()
        DispatchQueue.global(qos: .userInitiated).async {
            self.startRun()
        }
    }
    func loadDistribution(){
        print("load dist")
        init_distribution.removeAll()
        
        // point source at the center
        if initialSource == 0 {
            Array(0..<Int(history)).forEach{ _ in
                init_distribution.append(neutron(r:Position(z: 50),phi: Double.randPhi, theta: Double.randTheta))
            }
        } else {
            Array(0..<Int(history)).forEach{ _ in
                let gamma = 80 * Double.random(in: 0...1) + 10 // normal distribution
                init_distribution.append(neutron(r:Position(z: gamma),phi: Double.randPhi, theta: Double.randTheta))
            }
        }
        
        cyclsFissnSource.removeAll()
        cyclsFissnSource.append(FissionSourceDistr(cycle: 0, distribution: init_distribution))
        bankedFissionSource = init_distribution
        
        generateVisualFissionDistribution()

    }
    
    
    func startRun(){
        print("cycle: ")
        let startTime = DispatchTime.now().uptimeNanoseconds
        DispatchQueue.main.async {
            self.Keff_CyclesAvg = [Double]()
            self.Keff_Cycles1 = [Double]()
            self.Keff_Cycles2 = [Double]()
            self.Keff_Cycles3 = [Double]()
        }
        bankedFissionSource.removeAll()
        pre_bank_N = history
        bank_N = history
        keff_collision_Est = 0
        keff_absobrbtion_Est = 0
        keff_TrackLength_Est = 0
        
        loadData()
        loadDistribution()
        
        for i in 0...Int(cycles-1){
            if ForceStop {
                break
            }
            cycleLoop(i)
            generateVisualFissionDistribution()
            
            bankedFissionSource.removeAll()
            pre_bank_N = bank_N
            histories = pre_bank_N
            bank_N = 0
            keff_collision_Est = 0
            keff_absobrbtion_Est = 0
            keff_TrackLength_Est = 0
            
            regions.enumerated().forEach { (i,_) in
                regions[i].flux_coll = [0.0,0.0,0.0,0.0]
                regions[i].flux_length = [0.0,0.0,0.0,0.0]
             
            }
            surfaces.enumerated().forEach { (i,_) in
                surfaces[i].flux_surface = [0.0,0.0,0.0,0.0]
                surfaces[i].current = [0.0,0.0,0.0,0.0]
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
        print("currentCycle \(i)")
        
        for (h,n) in cyclsFissnSource[i].distribution.enumerated() {
            if ForceStop {
                break
            }
            // neutron distribution specturm as a history
            interactionLoop(n:n,cycle: i,history: h)
        }
        
//        let Keff0 = bank_N / pre_bank_N     // old method for Keff
        let Keff1 = keff_collision_Est/history
        let Keff2 = keff_absobrbtion_Est/history
        let Keff3 = keff_TrackLength_Est/history
        Keff = (Keff1+Keff2+Keff3)/3

        M_factor = history / bank_N
        print("Keff is \(Keff) for cycle: \(i) ,, M \(M_factor), bank_W \(bank_N),, bankedfission \(bankedFissionSource.count)")
        print("bankedFissionSource \(bank_N) ")
        DispatchQueue.main.async {
            self.currentCycle = i+1
            self.Keff_CyclesAvg.append(self.Keff)
            self.Keff_Cycles1.append(Keff1)
            self.Keff_Cycles2.append(Keff2)
            self.Keff_Cycles3.append(Keff3)
            
            self.KeffText = self.Keff
        }
        
        let fixedBankFission = reserveNumberOfHistories(bankedFissionSource)
        let newDistribution = FissionSourceDistr(cycle: i, distribution: fixedBankFission)
        cyclsFissnSource.append(newDistribution)
        
        if i >= inactiveC {
            let allRegionsTallies = regions.map { $0.tallies }
            let allSurfacesTallies = surfaces.map { $0.tallies }
            let tallies = CycleTallies(surface: allSurfacesTallies, cell: allRegionsTallies)
            
            DispatchQueue.main.async {
                self.Keff_CyclesToMeasure.append(self.Keff)
                self.cyclesTallies.append(tallies)
                self.cycleTallies = tallies
            }
        }
    }
    
    
    func interactionLoop(n:neutron,cycle:Int,history:Int){
        var n = n
        var x = n.r.x
        var y = n.r.y
        var z = n.r.z
        
        
        //        var gamma = Double.random(in: 0...1) // direction, isotropic point source ,
        var weight = n.w
        var group = (n.g == .group0) ? 0 : 1
        var region = getNeutronRegion(r: n.r) // current interaction region
        var xs = region.data[group] // current crosssection group
        
        
        DispatchQueue.main.async {
            self.particle = n
            self.particleHistory = [self.particle]
        }
        var isInteraction = true
        while isInteraction {
            if ForceStop {
                break
            }

            let d = -log(Double.rand)/xs.total
            let boundary = n.theta < 90 ? region.xRight : region.xLeft
            let lg = boundary - z
            let lc = d * n.theta.cosin
            
            x += d*n.phi.cosin // * n.theta.sinus
            y += d*n.phi.sinus // * n.theta.sinus

            if abs(lc) > abs(lg) {
                z = boundary + (n.theta < 90 ? 0.0001: -0.0001)
                
                regions[region.id].flux_length[group] += abs((weight*(0.0001+lg)/n.theta.cosin))
                if region.material == .Fuel {
                    keff_TrackLength_Est += weight * xs.v_fission * ((0.0001+lg)/n.theta.cosin)
                }
                
                let surfaceID = z<=leftBoundary ? Int(leftBoundary/10): (z >= rightBoundary ? Int(rightBoundary/10):Int(boundary/10))
                surfaces[surfaceID].flux_surface[group] += abs((weight)/n.theta.cosin)
                surfaces[surfaceID].current[group] += n.theta < 90 ? weight: -weight

                
                if z <= leftBoundary || z >= rightBoundary{
                    //# reflection or penetration or leakage
                    isInteraction = false
                } else {
                    // move neutron to boudndary and skip current iteration
                    // reserve neutron angle direction
                    updateParameters(theta: n.theta, phi: n.phi)
                }
                
            } else {
                // interaction within same region
                
                z += lc
                if region.material == .Fuel {
                    keff_collision_Est += weight * xs.v_fission/xs.total
                    keff_TrackLength_Est += weight * xs.v_fission * d
                }
                
                regions[region.id].flux_coll[group] +=  weight/xs.total
                regions[region.id].flux_length[group] += abs(d*weight)
                
                
                if isImpliciteCapture {
                    if Double.rand < (xs.absorb/xs.total) {
                        keff_absobrbtion_Est += weight * (xs.v_fission/xs.absorb)
                    }
                    
                    let new_n = Int((weight * (xs.v_fission/xs.total) * (1/Keff) ) + Double.rand) //  w = 1 for analog MC,
                    bankNeutrons(with: new_n)
                    
                    weight *= (xs.scatt/xs.total)

                    if weight<wLow {
                        animateRuss(w: weight,animate: true)
                        if Double.rand < (weight/wSurvive){
                            weight = wSurvive
                        } else {
                            print("kill particle")
                            isInteraction = false
                            animateRuss(w: weight,animate:false)
                        }
                    }
                    
                } else {
                    // check absorption probability
                    if Double.rand < xs.absorb/xs.total {
                        keff_absobrbtion_Est += weight * xs.v_fission/xs.absorb
                        
                        // check fission probability
                        if Double.rand < xs.fission/xs.total {
                            let new_n = Int((weight * xs.v / Keff ) + Double.rand)
                            bankNeutrons(with: new_n)
                        }
                        // else capture process
                        
                        isInteraction = false
                    }
                }
                
                if isInteraction {
                    updateGroup(with:Double.rand)
                    updateParameters(theta: Double.randTheta, phi: Double.randPhi)
                }

            }
        }
        
        func updateParameters(theta:Double,phi:Double){
            totalInteraction += 1
            
            let newPos = Position(x:x,y:y,z:z)
            n.r = newPos
            n.theta = theta
            n.phi = phi
            n.w = weight
            n.g = .allCases[group]
            region = getNeutronRegion(r: newPos) // update current region
            xs = region.data[group]  // update current cross section data from
            
            
            if self.animationEnabled {

                DispatchQueue.main.async {
                    self.animating.toggle()
                    self.particle = neutron(r: newPos, w: weight, g: .allCases[group], theta: theta)
                    self.particleHistory.append(self.particle)
                }

                let u_sec = 1000000.0
                usleep(useconds_t(animatingSpeed*u_sec))
            }
            
            //simulationLog.append("cycle: \(cycle), history # : \(history), n position : \(x),  in region: \(region.type) ")
        }
        
        func animateRuss(w:Double,animate:Bool){
            if self.animationEnabled {
                DispatchQueue.main.async {
                    self.animateRussianRollete = animate
                    self.killParticle = !isInteraction
                }
                let u_sec = 1000000.0
                usleep(useconds_t(animatingSpeed*u_sec))
                DispatchQueue.main.async {
                    self.animateRussianRollete = isInteraction
                    self.killParticle = false
                }
            }
        }
        
        func getNeutronRegion(r:Position) -> Region{
            
            return regions.filter {
                return r.z >= $0.xLeft && r.z <= $0.xRight
                
            }.first!
        }
        
        func bankNeutrons(with new_n:Int){
            if new_n != 0 {
                bank_N += Double(new_n)
                let bankedN =  neutron(r: Position(x:x,y: y,z: z),g: .group0,phi: Double.randPhi,theta: Double.randTheta)
                Array(0..<new_n).forEach{ _ in
                    bankedFissionSource.append(bankedN)
                }
            }
            //var fissionSpectrum = xs.fisnSpectrum_X // fast fission spectrum = 1
            //var neutron_group = 0 // fission spectrum is fixed for fast group X_fast=1 , X_thermal = 0
        }
        
        func updateGroup(with rand:Double){
            if rand < xs.scattGroup/xs.total {
                group = 1 // change cross sections group to thermal
            }
        }
        
        func isNeutronInVacuum(z:Double) -> Bool{
            if z<leftBoundary { //# reflection
                
                return true
            } else if z>rightBoundary{// penetration leakage
                
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
        guard !ForceStop else {ForceStop.toggle();return}
        
        let cycles = Double(activeC)
        print(Keff_CyclesToMeasure.count)
        
        let keffMean = Keff_CyclesToMeasure.reduce(0,+)/cycles
        let keffVar = ((pow(Keff_CyclesToMeasure,2) - pow(keffMean,2))/(cycles-1)).reduce(0,+)
        let keffSTD = keffVar.squareRoot()
        let keffFOM = 1/(keffVar*runTime)
        
        let cellCyclesTallies = cyclesTallies.map({$0.cell})
        let phi_coll_fast_data = cellCyclesTallies.map { regionTally in
            return regionTally.map { tallyType in
                return tallyType.first(where: {$0.type == .collision && $0.group == .group0 })!.score
            }
        }

        calculateFlux(type: "Phi Collision fast neutrons", data: phi_coll_fast_data)

        let phi_coll_therml_data = cellCyclesTallies.map { regionTally in
            return regionTally.map { tallyType in
                return tallyType.first(where: {$0.type == .collision && $0.group == .group1 })!.score
            }
        }
        calculateFlux(type: "Phi Collision thermal neutrons", data: phi_coll_therml_data)

        let phi_length_fast_data = cellCyclesTallies.map { regionTally in
            return regionTally.map { tallyType in
                return tallyType.first(where: {$0.type == .length && $0.group == .group0 })!.score
            }
        }
        calculateFlux(type: "Phi Track length Fast neutrons", data: phi_length_fast_data)

        let phi_length_therml_data = cellCyclesTallies.map { regionTally in
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
        
        
        
        let fuelGroup0 = Xs(id: 0, type: .group0, total: 0.22, absorb: 0.013, scattGroup: 0.02,v_fission: 0.0065,v: 2.6,X: 1.0)
        let fuelGroup1 = Xs(id: 1,type: .group1, total: 0.8, absorb: 0.18, scattGroup: 0.0, v_fission: 0.24, v: 2.4, X: 0.0)
        
        let reflectorGroup0 = Xs(id: 0,type: .group0, total: 0.2, absorb: 0.001, scattGroup: 0.035)
        let reflectorGroup1 = Xs(id: 1,type: .group1, total: 0.95, absorb: 0.05, scattGroup: 0.0)
        
        let currentRegions = regions
        currentRegions.enumerated().forEach { i,reg in
            if reg.material == .Fuel {
                regions[i].data = [fuelGroup0,fuelGroup1]
            } else {
                regions[i].data = [reflectorGroup0,reflectorGroup1]
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
        if true {
            distr = distr.map({ n in
                var n = n
                n.w = M_factor
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
    
    
    func generateVisualFissionDistribution(){
        let dict = Dictionary(grouping: bankedFissionSource, by: {Double(Int($0.r.z*10)/10)})
        DispatchQueue.main.async {
            self.fissionDistrDraw = dict
        }
    }
}
