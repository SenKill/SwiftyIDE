//
//  IDECommands.swift
//  SwiftyIDE
//
//  Created by Serik Musaev on 06.04.2025.
//

import SwiftUI

struct IDECommands: Commands {
    @Binding var isProgramRunning: Bool
    var onRunCommand: () -> Void
    var onStopCommand: () -> Void
    
    var body: some Commands {
        CommandMenu("Product") {
            Button("Run", action: onRunCommand)
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(isProgramRunning)
            Button("Stop", action: onStopCommand)
                .keyboardShortcut("s", modifiers: [.command])
                .disabled(!isProgramRunning)
        }
    }
}
