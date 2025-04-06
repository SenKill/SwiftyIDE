# SwiftyIDE

💻 The MacOS application justo to write some Swift code and quickly see the results!

It's functionality simple yet just enough for writing and compiling scripts. 
The app is written in Swift language and is for coding in Swift language. The interface is minimalistic so nothing will distract you from locking in!

## How to run

A device with **MacOS** is needed.
Simply clone the project and open it using **Xcode**, then **select MacOS as a target** and just compile it on your device.
Run your code using button on the upper right corner, or using command in the "Product" section on the upper side, you can use hotkeys like Cmd+R and Cmd+S too!

## Preview

<img width="1440" alt="Screenshot 2025-04-07 at 0 02 21" src="https://github.com/user-attachments/assets/1b1ac1d2-c9d8-420a-80f7-f4e4be9cbaf0" />

## Implemented Features

Hyperlinks lead to short demonstrations
- Both **editor** and **output** panes;
- **Swift code compiling** as a base;
- **Code highlighting** - where number of keywords could easily be increased without significant optimization problems;
- **Editor gutter** on the left side of the editor with **line numbers**;
- **Live code output**:

https://github.com/user-attachments/assets/fa5f51bd-4bc1-4552-b94f-04e08746f279


- Visual intuitive **indicators** running code, errors and successful runs:


https://github.com/user-attachments/assets/4f534ff9-a4c1-49e8-8b71-1fe3fac5d29d

- Display of **returns codes** in the output;
- **Interactable errors** in from the descriptions with a locations (hyperlink navigation):

https://github.com/user-attachments/assets/15988b5e-79be-4ead-a9ef-75a6932d5a61

- **Auto tabulation** when detecting opening braces:

https://github.com/user-attachments/assets/2ccdbf84-bf5c-40a6-997f-c8bcbbffd95c

- **Hotkeys** for running and stopping script

- [Dark theme](https://github.com/SenKill/SwiftyIDE/blob/main/Movies/Screenshot%202025-04-07%20at%200.54.25.png);
- JetBrains' mono fonts 😏;

## Technologies and Instruments

- Swift language (ver. 6) ✅
- SwiftUI as a main UI framework ✅
- AppKit using NSViewRepresentable, because some SwiftUI views don't allow to configure them as wanted ✅
- MVVM architecture ✅
- No external libraries ✅

