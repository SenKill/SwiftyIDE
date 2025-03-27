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
    private var outputSource: DispatchSourceRead?
    
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
        outputSource?.cancel()
        outputSource = nil
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
            readOutputPipe(from: outputPipe)
            // Runs concurrently
            process.terminationHandler = onScriptTermination
            try process.run()
            return true
        } catch let error as NSError {
            print("ERROR: Failed to run script: \(error.localizedDescription)")
            return false
        }
    }
    
    private func readOutputPipe(from outputPipe: Pipe) {
        // Passing the output pipe's file descriptor and async queue to read from the output pipe to an DispatchSource object which is used to read data from streams
        self.outputSource = DispatchSource.makeReadSource(
            fileDescriptor: outputPipe.fileHandleForReading.fileDescriptor,
            queue: DispatchQueue.global(qos: .userInitiated))
        // Whenever there are any events check for new output
        outputSource?.setEventHandler { [weak self] in
            let data = outputPipe.fileHandleForReading.availableData
            if let outputString = try? NSAttributedString(data: data, documentAttributes: nil) {
                // Making changes on the main queue
                DispatchQueue.main.async {
                    self?.outputAppendPublisher.send(outputString)
                }
            }
        }
        outputSource?.resume()
    }
    
    @Sendable
    private func onScriptTermination(_ process: Process?) {
        guard   let process = process,
                let errorPipe = process.standardError as? Pipe else {
            DispatchQueue.main.async {
                self.isScriptRunning = false
            }
            print("ERROR: Couldn't get script's process or error pipe")
            runningProcess = nil
            return
        }
        let errorData = try? errorPipe.fileHandleForReading.readToEnd()
        
        DispatchQueue.main.async {
            // Print out error output if there any
            if let errorData = errorData,
               let error = String(data: errorData, encoding: .utf8) {
                let errorTextAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 12),
                    .foregroundColor: NSColor.red
                ]
                let errorAttrString = NSAttributedString(string: error, attributes: errorTextAttributes)
                self.outputAppendPublisher.send(errorAttrString)
            }
            let termStatusAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12, weight: .medium)
            ]
            let termStatusAttrString = NSAttributedString(string: "\nProcess exited with code \(process.terminationStatus)\n\n", attributes: termStatusAttributes)
            self.outputAppendPublisher.send(termStatusAttrString)
            self.isScriptRunning = false
        }
        runningProcess = nil
        outputSource?.cancel()
        outputSource = nil
    }
}
