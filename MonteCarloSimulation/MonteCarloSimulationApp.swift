//
//  MonteCarloSimulationApp.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 06/11/2022.
//

import SwiftUI
import FirebaseCore
import FirebaseAppCheck
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)

        return true
    }
}

@main
struct MonteCarloSimulationApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            TabBarView()
                .preferredColorScheme(.dark)  // Forces dark mode
        }
    }
}
