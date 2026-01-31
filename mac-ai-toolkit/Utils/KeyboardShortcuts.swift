//
//  KeyboardShortcuts.swift
//  mac-ai-toolkit
//
//  Global keyboard shortcuts management
//

import Foundation
import Carbon
import AppKit

@MainActor
class KeyboardShortcutsManager: ObservableObject {
    static let shared = KeyboardShortcutsManager()

    private var eventHandlerRef: EventHandlerRef?
    private var registeredHotKeys: [UInt32: () -> Void] = [:]
    private var nextHotKeyID: UInt32 = 1

    private init() {}

    // MARK: - Registration

    func register(
        keyCode: UInt32,
        modifiers: UInt32,
        handler: @escaping () -> Void
    ) -> UInt32? {
        let hotKeyID = nextHotKeyID
        nextHotKeyID += 1

        var eventHotKey: EventHotKeyRef?
        var hotKeyIDStruct = EventHotKeyID(signature: OSType(0x4D415449), id: hotKeyID) // 'MATI'

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyIDStruct,
            GetApplicationEventTarget(),
            0,
            &eventHotKey
        )

        guard status == noErr else {
            return nil
        }

        registeredHotKeys[hotKeyID] = handler

        // Install event handler if not already installed
        if eventHandlerRef == nil {
            installEventHandler()
        }

        return hotKeyID
    }

    func unregister(hotKeyID: UInt32) {
        registeredHotKeys.removeValue(forKey: hotKeyID)
    }

    func unregisterAll() {
        registeredHotKeys.removeAll()
    }

    // MARK: - Default Shortcuts

    func registerDefaultShortcuts() {
        // ⌘ + Shift + O: Screenshot OCR
        _ = register(
            keyCode: UInt32(kVK_ANSI_O),
            modifiers: UInt32(cmdKey | shiftKey)
        ) {
            NotificationCenter.default.post(name: .screenshotOCR, object: nil)
        }

        // ⌘ + Shift + T: Quick TTS
        _ = register(
            keyCode: UInt32(kVK_ANSI_T),
            modifiers: UInt32(cmdKey | shiftKey)
        ) {
            NotificationCenter.default.post(name: .quickTTS, object: nil)
        }

        // ⌘ + Shift + S: Quick STT
        _ = register(
            keyCode: UInt32(kVK_ANSI_S),
            modifiers: UInt32(cmdKey | shiftKey)
        ) {
            NotificationCenter.default.post(name: .quickSTT, object: nil)
        }
    }

    // MARK: - Private

    private func installEventHandler() {
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        let handlerBlock: EventHandlerUPP = { _, event, _ in
            var hotKeyID = EventHotKeyID()

            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            guard status == noErr else {
                return OSStatus(eventNotHandledErr)
            }

            Task { @MainActor in
                if let handler = KeyboardShortcutsManager.shared.registeredHotKeys[hotKeyID.id] {
                    handler()
                }
            }

            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            handlerBlock,
            1,
            &eventSpec,
            nil,
            &eventHandlerRef
        )
    }
}

// MARK: - Key Code Mapping

extension KeyboardShortcutsManager {

    static func keyCode(for character: String) -> UInt32? {
        let mapping: [String: Int] = [
            "a": kVK_ANSI_A, "b": kVK_ANSI_B, "c": kVK_ANSI_C, "d": kVK_ANSI_D,
            "e": kVK_ANSI_E, "f": kVK_ANSI_F, "g": kVK_ANSI_G, "h": kVK_ANSI_H,
            "i": kVK_ANSI_I, "j": kVK_ANSI_J, "k": kVK_ANSI_K, "l": kVK_ANSI_L,
            "m": kVK_ANSI_M, "n": kVK_ANSI_N, "o": kVK_ANSI_O, "p": kVK_ANSI_P,
            "q": kVK_ANSI_Q, "r": kVK_ANSI_R, "s": kVK_ANSI_S, "t": kVK_ANSI_T,
            "u": kVK_ANSI_U, "v": kVK_ANSI_V, "w": kVK_ANSI_W, "x": kVK_ANSI_X,
            "y": kVK_ANSI_Y, "z": kVK_ANSI_Z,
            "0": kVK_ANSI_0, "1": kVK_ANSI_1, "2": kVK_ANSI_2, "3": kVK_ANSI_3,
            "4": kVK_ANSI_4, "5": kVK_ANSI_5, "6": kVK_ANSI_6, "7": kVK_ANSI_7,
            "8": kVK_ANSI_8, "9": kVK_ANSI_9,
        ]

        guard let code = mapping[character.lowercased()] else {
            return nil
        }

        return UInt32(code)
    }

    static func modifiers(command: Bool = false, shift: Bool = false, option: Bool = false, control: Bool = false) -> UInt32 {
        var mods: UInt32 = 0
        if command { mods |= UInt32(cmdKey) }
        if shift { mods |= UInt32(shiftKey) }
        if option { mods |= UInt32(optionKey) }
        if control { mods |= UInt32(controlKey) }
        return mods
    }
}
