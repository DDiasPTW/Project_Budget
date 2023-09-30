//
//  MyBudgetAppApp.swift
//  MyBudgetApp
//
//  Created by Diogo Dias on 26/09/2023.
//

import SwiftUI

@main
struct MyBudgetAppApp: App {
    
    init() {
        // Initialize UserDefaults key "balance" with a default value of 0
        UserDefaults.standard.register(defaults: ["balance": 0.0])
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
