//
//  StaffLanka_GoApp.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-03-23.
//

import SwiftUI

@main
struct StaffLanka_GoApp: App {
    @StateObject private var auth = AuthManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
        }
    }
}
