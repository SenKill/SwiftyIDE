//
//  IDEViewModel.swift
//  SwiftyIDE
//
//  Created by Serik Musaev on 24.03.2025.
//

import SwiftUI
import Combine

final class IDEViewModel: ObservableObject {
    @Published var codeText: String = ""
    @Published var isScriptRunning: Bool = false
    // Publisher to communicate with custom NSTextView on which is used to present output
    let outputAppendPublisher = PassthroughSubject<NSAttributedString?, Never>()
    
    private var runningProcess: Process?
    
    func runScript() {
        runningProcess?.terminate()
        guard let url = saveScript() else {
            print("ERROR: Couldn't save the script")
            return
        }
        runScript(with: url)
    }
    
    func stopScript() {
        runningProcess?.terminate()
        runningProcess = nil
    }
    
    func clearOutput() {
        // `nil` = clear output
        self.outputAppendPublisher.send(nil)
    }
    
    // Returns new script's url
    private func saveScript() -> URL? {
        // Save tmp file in temp directory
        let baseUrl = FileManager.default.temporaryDirectory
        let completeUrl = baseUrl.appendingPathComponent("foo").appendingPathExtension("swift")
        do {
            try codeText.write(to: completeUrl, atomically: true, encoding: .utf8)
            return completeUrl
        } catch let error as NSError {
            print("ERROR: An error happened during file writing \"\(error.localizedDescription)\"")
            return nil
        }
    }
    
    @discardableResult
    private func runScript(with url: URL) -> Bool {
        // To be sure :)
        stopScript()
        // A class to run and track an executable
        // MARK: Doesn't show live output
        // TODO: Make live output
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        // URL that searches for Swift compiler in PATH
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["swift", url.path()]
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            runningProcess = process
            isScriptRunning = true
            try process.run()
            // Runs concurrently
            process.terminationHandler = onScriptTermination
            return true
        } catch let error as NSError {
            print("ERROR: Failed to run script: \(error.localizedDescription)")
            return false
        }
    }
        
    @Sendable
    private func onScriptTermination(_ process: Process?) {
        guard   let process = process,
                let outputPipe = process.standardOutput as? Pipe,
                let errorPipe = process.standardError as? Pipe else {
            DispatchQueue.main.async {
                self.isScriptRunning = false
            }
            print("ERROR: Couldn't get script's process or pipes")
            runningProcess = nil
            return
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        // Switch to main thread
        DispatchQueue.main.async {
            var commonTextAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.black
            ]
            
            if let output = String(data: outputData, encoding: .utf8), !output.isEmpty {
                let attrString = NSAttributedString(string: output, attributes: commonTextAttributes)
                self.outputAppendPublisher.send(attrString)
            } else if let error = String(data: errorData, encoding: .utf8) {
                commonTextAttributes[.foregroundColor] = NSColor.systemRed
                let attrString = NSAttributedString(string: error, attributes: commonTextAttributes)
                self.outputAppendPublisher.send(attrString)
            }
            self.isScriptRunning = false
        }
        runningProcess = nil
    }
}
