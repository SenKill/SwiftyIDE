//
//  CodeEditorView.swift
//  SwiftyIDE
//
//  Created by Serik Musaev on 07.03.2025.
//

import SwiftUI

struct CodeEditorView: View {
    @StateObject private var vm = CodeEditorViewModel()
    
    var body: some View {
        EditorTextView(text: $vm.text)
    }
}

#Preview {
    CodeEditorView()
}
