//
//  SeeUCafeDeliveryAppApp.swift
//  SeeUCafeDeliveryApp
//
//  Created by mac on 11/6/25.
//

import SwiftUI

@main
struct SeeUCafeDeliveryAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
