//
//  SwiftyIDEApp.swift
//  SwiftyIDE
//
//  Created by Serik Musaev on 07.03.2025.
//

import SwiftUI

@main
struct SwiftyIDEApp: App {
    // Manually loading all fonts..
    private func registerFonts() {
        let fontNames = [
            "JetBrainsMonoNL-Light",
            "JetBrainsMonoNL-Regular",
            "JetBrainsMonoNL-Medium",
            "JetBrainsMonoNL-SemiBold",
            "JetBrainsMonoNL-Bold"
        ]

        for name in fontNames {
            guard let fontURL = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                print("ERROR: Font \(name) wasn't found in bundle.")
                continue
            }

            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
                print("ERROR: Font registration failed for \(name): \(error.debugDescription)")
            }
        }
    }
    
    init() {
        registerFonts()
    }
    
    @StateObject private var ideVm = IDEViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ideVm)
        }
        .commands {
            IDECommands(
                isProgramRunning: $ideVm.isScriptRunning,
                onRunCommand: ideVm.runScript, onStopCommand: ideVm.stopScript
            )
        }
    }
}
