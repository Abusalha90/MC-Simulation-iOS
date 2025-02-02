//
//  fluxEstimationClass.swift
//  abusalha
//
//  Created by Mohammad Abusalha on 06/11/2022.
//

import Foundation

class simu_data:ObservableObject{
    
    @Published var isRunning: Bool = false

    @Published var batch1 = ""
    @Published var batch = 5
    @Published var histories = 100

    //   case A
    @Published var segma_Sctr = 0.9
    @Published var segma_Abs = 0.1
    var segma_tot : Double{
        return segma_Abs + segma_Sctr
    }
    @Published var widthTot = 10 // slab width
    @Published var volumeIndex = 1 //  number of intervals
    @Published var numberOfSlabs = [1,2,10] //  number of intervals

    var dx : Double {
        let numb = Double(widthTot)/Double(numberOfSlabs[volumeIndex])
        let rounded = Double(round(10 * numb) / 10)
        
        return rounded // slab interval thickness
    }
    
    var volumes_list: [Int] {
        //[0,1,2,3,4,5,6,7,8,9]
        // volume Distance x from its border
        switch volumeIndex{
        case 1:
            return [0,5]
        case 2:
            return [0,1,2,3,4,5,6,7,8,9]
        default:
            return [0]
        }
    }

    var volumes_Figures: [Double] {
        //[1,2,3,4,5,6,7,8,9,10]
//        return Array(stride(from: 0.0, through: Double(widthTot), by: dx))
        switch volumeIndex{
        case 1:
            return [0,5,10]
        case 2:
            return [0,1,2,3,4,5,6,7,8,9,10]
        default:
            return [0,10]
        }
    }

    
    lazy var arrVol = Array(repeating: 0.0, count: numberOfSlabs[volumeIndex])
    @Published var mean_Coll = [Double]()
    @Published var mean_Track = [Double]()
    @Published var var_collision = [Double]()
    @Published var var_track = [Double]()
    @Published var std_collision = [Double]()
    @Published var std_Track = [Double]()

    var collisions = [[Double]]()
    var track_length = [[Double]]()
    
    var transmisions = [Double]()
    var captured = [Double]()
    var reflected = [Double]()
    
    func resetMean(){
        arrVol = Array(repeating: 0.0, count: numberOfSlabs[volumeIndex])
        mean_Coll = arrVol
        mean_Track = arrVol
        collisions = [[Double]]()
        track_length = [[Double]]()
    }
    
    func resetVariance(){
        arrVol = Array(repeating: 0.0, count: numberOfSlabs[volumeIndex])
        var_collision = arrVol
        var_track = arrVol
        std_collision = arrVol
        std_Track = arrVol
    }
    
    func run(){
        resetMean()
        isRunning.toggle()
        DispatchQueue.global(qos: .userInitiated).async {
            self.startRun()
        }
    }
    
    func startRun(){
        for i in 0...self.batch-1{
            collisions = [[Double]]()
            track_length = [[Double]]()

            historyLoop(batch:i)
            mean_Coll = zip(mean_Coll,collisions[i]).map{($0.0+$0.1)/Double(batch)}
//            print(mean_Coll)
            mean_Track = zip(mean_Track,track_length[i]).map{($0.0+$0.1)/Double(batch)}
            if i == batch - 1 {
                DispatchQueue.main.async {
                    self.isRunning.toggle()
                    self.getVarinace()
                }
            }
        }
    }
    
 
    func historyLoop(batch i:Int){
//        print("i batch = \(i)")
        for j in 0...histories-1{
            collisions.append(arrVol)
            track_length.append(arrVol)

            let interactionLoop = interactionLoop(forHistory:j)
            let coll = interactionLoop.0
            let lngth = interactionLoop.1
            
            let coll_array = coll.map{($0/Double(histories))} // divided by batch modifier to prevent accumlation
//            print(collisions)
            collisions[j] = zip(collisions[j],coll_array).map(+)
            
            let length_array = lngth.map{($0/Double(histories))}
            track_length[j] = zip(track_length[j],length_array).map(+)
 
        }
//        print("collision")
//        print(collision)
    }

    func interactionLoop(forHistory j:Int) -> ([Double],[Double]){
        var vol_collision = arrVol
        var length = arrVol
        var x_init = 0.0
        var x = 0.0
        var rand = 1.0
//            # initially fixed direction towards the slap
       
        var interaction = true
        while interaction {

            let lamda = Double.random(in: 0...1)
            let s = -log(lamda)/segma_tot
            x = x_init + s*rand
            var betweenVolumse = 0..<1
            
            let k = volumes_list.lastIndex(where: { x_init >= Double($0) }) ?? 0 // #initital volume index
            var u = volumes_list.lastIndex(where: { x >= Double($0) }) ?? 0
             //# index of interaction in volumes [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
            
            if x<0 || x>10{ //# reflection or penetration leakage
                u = x<0 ? 0:10
                let in_vol_distance = x<0 ?
                abs(x_init - Double(volumes_list[k])) :
                abs(x_init - Double(volumes_list[k]+1))
                length[k] += in_vol_distance //# initital volume distance
                if volumeIndex == 2 { // 10 volumes
                    betweenVolumse = x<0 ? u..<k : (k+1)..<u
                }
                
                interaction = false
            } else {
                vol_collision[u] += 1 //# flux by interaction
                if x_init < Double(volumes_list[u]) {
                    // #  penetration from previous volume
                    length[u] += abs(x - Double(volumes_list[u]))// #current volume distance
                    length[k] += abs(x_init - Double(volumes_list[k])) //# initital volume distance
                    if volumeIndex == 2 {
                        betweenVolumse = (k+1)..<u
                    }
                } else if x < Double(volumes_list[k]) {
                    //# reflection from next volume
                    length[u] += abs(Double(volumes_list[k]) - x) //# current volume
                    length[k] += abs(x_init - Double(k)) //# initital volume distance
                    if volumeIndex == 2 {
                        betweenVolumse = (u+1)..<k
                    }
                } else { //# interaction within the volume
                    length[u] += abs(x - x_init)
                }
                
                if volumeIndex == 2 {
                    for a in betweenVolumse {
                        // print("volumeRng penetration")
                        // # in between volumes distance fill
                        length[a] += 1.0
                    }
                }
                
                rand = Double.random(in: 0...1)
                if (rand<(segma_Abs/segma_tot)){
                    interaction = false
                } else {
                    interaction = true
                    rand = Double.random(in: -1...1)
                    x_init = x
                }
            }
        }
    
        return (vol_collision,length)
    }
    
    
    func getVarinace(){
        resetVariance()
        for i in 0...batch-1{
            let vColl = zip(collisions[i],mean_Coll).map{pow($0.0-$0.1,2)}
            let vTrack = zip(track_length[i], mean_Track).map{pow($0.0-$0.1,2)}
            
            var_collision = zip(var_collision,vColl).map{($0.0+$0.1)/Double(batch-1)}
            var_track = zip(var_track,vTrack).map{($0.0+$0.1)/Double(batch-1)}
        }
        mean_Coll = mean_Coll.map{$0/(dx*segma_tot)}
        mean_Track = mean_Track.map{$0/dx}

        std_collision = var_collision.map{($0/Double(batch)).squareRoot()*(1/(dx*segma_tot))}
        std_Track = std_Track.map{($0/Double(batch)).squareRoot()}
        
        printResults()
    }
    
    func printResults(){
        var list1 = [[],[]]
        var list2 = [[],[]]
        var list3 = [[],[]]
        for i in 0..<numberOfSlabs[volumeIndex]{
            list1[0].append(mean_Coll[i])
            list2[0].append(var_collision[i])
            list3[0].append(std_collision[i])
            
            list1[1].append(mean_Track[i])
            list2[1].append(var_track[i])
            list3[1].append(std_Track[i])
            print( "Flux Collision Estimator in volume" , String(i+1), "=", String(mean_Coll[i]), "Variance= " + String(var_collision[i]) + " StD= " + String(std_collision[i]))
            print("Flux Track length Estimator in volume", String(i+1), "=", String(mean_Track[i]),"Variance= ", String(var_track[i])," StD= ",String(std_Track[i]))
            print("----------------------------")
            
        }
        print(list1)
        print(list2)
        print(list3)
    }
 
   
}
