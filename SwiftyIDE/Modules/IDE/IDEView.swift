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
    @StateObject private var vm = IDEViewModel()
    @FocusState private var currentFocus: CurrentFocus?
    
    var body: some View {
        VerticalNavigationSplitView {
            EditorTextView(text: $vm.codeText)
                .focused($currentFocus, equals: .editor)
                .frame(minHeight: 500)
                .padding(.zero)
        } outputContent: {
            OutputTextView(appendPublisher: vm.outputAppendPublisher)
                .focused($currentFocus, equals: .output)
                .frame(minHeight: 100)
                .padding(.top)
                .overlay(alignment: .topTrailing) {
                    Button {
                        vm.clearOutput()
                    } label: {
                        Image(systemName: "xmark.bin.fill")
                    }
                    .padding()
                }
            
        }
        .onAppear {
            currentFocus = .editor
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        vm.runScript()
                    } label: {
                        Image(systemName: "play.fill")
                    }
                    .disabled(vm.isScriptRunning)
                
            } label: {
                Text("Compile program")
            }
            ToolbarItemGroup(placement: .cancellationAction) {
                Button {
                    vm.stopScript()
                } label: {
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
