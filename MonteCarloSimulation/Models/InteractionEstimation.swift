//
//  InteractionEstimation.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 09/11/2022.
//

import Foundation
//
//  fluxEstimationClass.swift
//  abusalha
//
//  Created by Mohammad Abusalha on 06/11/2022.
//

import Foundation

class Interaction_simu_data:ObservableObject{
    
    @Published var isRunning: Bool = false

    @Published var batch = 5.0
    @Published var histories = 100.0

    //   case A
    @Published var segma_Sctr = 0.7
    @Published var segma_Abs = 0.3
    var segma_tot : Double{
        return segma_Abs + segma_Sctr
    }
    @Published var widthTot = 10 // slab width
  
    var transmisions = 0.0
    var captured = 0.0
    var reflected = 0.0
    

    var batchArrTransmisions = [Double]()
    var batchArrCaptured = [Double]()
    var batchArrReflected = [Double]()

    var batchMeanTransmisions = 0.0
    var batchMeanCaptured = 0.0
    var batchMeanReflected = 0.0
    
    var varReflected = 0.0
    var varTransmisions = 0.0
    var varCaptured = 0.0
    
    var totalInteraction = 0
    func resetValues(){
        transmisions = 0
        captured = 0
        reflected = 0
        
        batchArrTransmisions = [Double]()
        batchArrCaptured = [Double]()
        batchArrReflected = [Double]()

        batchMeanTransmisions = 0.0
        batchMeanCaptured = 0.0
        batchMeanReflected = 0.0
        
        varReflected = 0.0
        varTransmisions = 0.0
        varCaptured = 0.0

        totalInteraction = 0
    }
    
    func run(){
        resetValues()
        isRunning.toggle()
        DispatchQueue.global(qos: .userInitiated).async {
            self.startRun()
        }
    }
    
    func startRun(){
        for i in 0...Int(batch-1){
            transmisions = 0
            reflected = 0
            captured = 0
            historyLoop(batch:i)
            batchMeanTransmisions = batchArrTransmisions.reduce(0,+)/batch
            batchMeanReflected = batchArrReflected.reduce(0,+)/batch
            batchMeanCaptured = batchArrCaptured.reduce(0,+)/batch
            
            if i == Int(batch-1) {
                DispatchQueue.main.async {
                    self.isRunning.toggle()
                    self.getVarinace()
                }
            }
            
        }
    }
    
 
    func historyLoop(batch i:Int){
        for j in 0...Int(histories-1){
            interactionLoop(forHistory:j)
        }
        batchArrTransmisions.append(transmisions/histories)
        batchArrReflected.append(reflected/histories)
        batchArrCaptured.append(captured/histories)

    }

    func interactionLoop(forHistory j:Int){
        var x_init = 0.0
        var x = 0.0
        var rand = 1.0
//            # initially fixed direction towards the slap
       
        var interaction = true
        while interaction {

            let lamda = Double.random(in: 0...1)
            let s = -log(lamda)/segma_tot
            x = x_init + s*rand
            
            totalInteraction += 1

            interaction = false
            if x<0 { //# reflection
                reflected += 1
            } else if x>10{// penetration leakage
                transmisions += 1
            } else {
                rand = Double.random(in: 0...1)
                if (rand<(segma_Abs/segma_tot)){
                    captured += 1
                } else {
                    interaction = true
                    rand = Double.random(in: -1...1)
                    x_init = x
                }
            }
        }

    }
    
    
    func getVarinace(){
//        print(batchArrReflected)
//        print(batchMeanReflected)
        print(varReflected)
        for i in 0...Int(batch-1){
            varReflected += (pow(batchArrReflected[i],2) - pow(batchMeanReflected,2))
            varTransmisions += (pow(batchArrTransmisions[i],2) - pow(batchMeanTransmisions,2))
            varCaptured += (pow(batchArrCaptured[i],2) - pow(batchMeanCaptured,2))
        }
        let reflectedSTD = (varReflected/Double((batch-1))).squareRoot()
        let transmisionSTD = (varTransmisions/Double((batch-1))).squareRoot()
        let capturedSTD = (varCaptured/Double((batch-1))).squareRoot()

        print("probability of reflection : \(batchMeanReflected) , variance : \(varReflected) ,StD = \(reflectedSTD)")
        print("probability of transportation : \(batchMeanTransmisions) , variance : \(varTransmisions)  , StD =  \(transmisionSTD)")
        print("probability of absorption :  \(batchMeanCaptured) , variance : \(varCaptured)  , StD = \(capturedSTD)")
        print("totalInteraction")
//        print(totalInteraction)
//        print(reflected)
//        print(transmisions)
//        print(captured)
    }
    
 
   
}
