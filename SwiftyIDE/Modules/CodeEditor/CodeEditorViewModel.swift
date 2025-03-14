//
//  CodeEditorViewModel.swift
//  SwiftyIDE
//
//  Created by Serik Musaev on 07.03.2025.
//

import SwiftUI

final class CodeEditorViewModel: ObservableObject {
    // MARK: Public variables
    @Published var text: String = ""
}
