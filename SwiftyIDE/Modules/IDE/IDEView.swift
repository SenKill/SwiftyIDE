//
//  IDEView.swift
//  SwiftyIDE
//
//  Created by Serik Musaev on 24.03.2025.
//

import SwiftUI

enum CurrentFocus {
    case editor, output
}

struct IDEView: View {
    @EnvironmentObject private var vm: IDEViewModel
    @FocusState private var currentFocus: CurrentFocus?
    
    var body: some View {
        VerticalNavigationSplitView {
            EditorTextView(text: $vm.codeText)
                .focused($currentFocus, equals: .editor)
                .frame(minHeight: 500)
                .padding(.zero)
        } outputContent: {
            let commonPadding: CGFloat = vm.didErrorHappen ? 2 : 0
            OutputTextView(appendPublisher: vm.outputAppendPublisher)
                .focused($currentFocus, equals: .output)
                .frame(minHeight: 100)
                .padding(commonPadding)
                .overlay(alignment: .topTrailing) {
                    Button(action: vm.clearOutput) {
                        Image(systemName: "xmark.bin.fill")
                    }
                    .padding(commonPadding)
                    // Padding from the text view's scroller
                    .padding(.trailing, 20)
                    .animation(.easeInOut(duration: 0.2), value: vm.didErrorHappen)
                }
                .background(vm.didErrorHappen ? Color.pink : Color.green)
                .animation(.easeInOut(duration: 0.2), value: vm.didErrorHappen)
        }
        .onAppear {
            currentFocus = .editor
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: vm.runScript) {
                    Image(systemName: "play.fill")
                }
                .disabled(vm.isScriptRunning)
            } label: {
                Text("Compile program")
            }
            ToolbarItemGroup(placement: .cancellationAction) {
                Button(action: vm.stopScript) {
                    Image(systemName: "stop.fill")
                }
                .disabled(!vm.isScriptRunning)
            } label: {
                Text("Stop program")
            }
            if vm.isScriptRunning {
                ToolbarItemGroup(placement: .principal) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.small)
                } label: {
                    Text("Program is running")
                }
            } else {
                ToolbarItemGroup(placement: .principal) {
                    Image(systemName: vm.didErrorHappen ? "x.circle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(vm.didErrorHappen ? .red : .green)
                } label: {
                    Text(vm.didErrorHappen ? "Program returned an error" : "Program compiled successfully")
                }
            }
        }
    }
}

#Preview {
    IDEView()
}
