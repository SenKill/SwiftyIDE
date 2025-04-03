//
//  SwiftyIDEApp.swift
//  SwiftyIDE
//
//  Created by Serik Musaev on 07.03.2025.
//

import SwiftUI

// Manually loading all fonts..
func registerFonts() {
    let fontNames = [
        "JetBrainsMono-Light",
        "JetBrainsMono-Regular",
        "JetBrainsMono-Medium",
        "JetBrainsMono-SemiBold",
        "JetBrainsMono-Bold"
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

@main
struct SwiftyIDEApp: App {
    
    init() {
        registerFonts()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
