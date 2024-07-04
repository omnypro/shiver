//
//  OSKit.swift
//  Shiver
//
//  Created by Bryan Veloso on 7/4/24.
//  Derived from: https://gist.github.com/nicklockwood/19569dc738b565c67f4d97302bf48697
//

import SwiftUI

enum OSDocumentError: Error {
    case unknownFileFormat
}

#if canImport(UIKit)

import UIKit

typealias OSApplicationDelegateAdaptor = UIApplicationDelegateAdaptor
typealias OSApplicationDelegate = UIApplicationDelegate
typealias OSLongPressGestureRecognizer = UILongPressGestureRecognizer
typealias OSTapGestureRecognizer = UITapGestureRecognizer
typealias OSWorkspace = UIApplication
typealias OSView = UIView
typealias OSColor = UIColor

extension UIResponder {
    var nextResponder: UIResponder? { next }
}

protocol OSViewRepresentable: UIViewRepresentable {
    associatedtype OSViewType: UIView

    func makeOSView(context: Context) -> OSViewType
    func updateOSView(_ osView: OSViewType, context: Context)
}

extension OSViewRepresentable {
    func makeUIView(context: Context) -> OSViewType {
        makeOSView(context: context)
    }

    func updateUIView(_ uiView: OSViewType, context: Context) {
        updateOSView(uiView, context: context)
    }
}

class OSDocument: UIDocument {
    func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {}
    func fileWrapper(ofType typeName: String) throws -> FileWrapper { fatalError() }

    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let fileWrapper = contents as? FileWrapper,
              fileWrapper.isDirectory
        else {
            throw OSDocumentError.unknownFileFormat
        }
        try read(from: fileWrapper, ofType: typeName ?? "")
    }

    override func contents(forType typeName: String) throws -> Any {
        try fileWrapper(ofType: typeName)
    }

    override func handleError(_ error: Error, userInteractionPermitted: Bool) {
        print(error)
        super.handleError(error, userInteractionPermitted: userInteractionPermitted)
    }
}

#elseif canImport(AppKit)

import AppKit

typealias OSApplicationDelegateAdaptor = NSApplicationDelegateAdaptor
typealias OSApplicationDelegate = NSApplicationDelegate
typealias OSLongPressGestureRecognizer = NSPressGestureRecognizer
typealias OSTapGestureRecognizer = NSClickGestureRecognizer
typealias OSWorkspace = NSWorkspace
typealias OSView = NSView
typealias OSColor = NSColor

protocol OSViewRepresentable: NSViewRepresentable where NSViewType == OSViewType {
    associatedtype OSViewType: NSView

    func makeOSView(context: Context) -> OSViewType
    func updateOSView(_ osView: OSViewType, context: Context)
}

extension OSViewRepresentable {
    func makeNSView(context: Context) -> OSViewType {
        makeOSView(context: context)
    }

    func updateNSView(_ nsView: OSViewType, context: Context) {
        updateOSView(nsView, context: context)
    }
}

extension NSDocument {
    func open(_ completion: ((Bool) -> Void)?) {
        Task {
              let success = await open()
              completion?(success)
        }
    }

    func open() async -> Bool {
        guard let fileURL else {
            return false
        }
        do {
            try read(from: fileURL, ofType: fileType ?? "")
            return true
        } catch {
            return false
        }
    }

    func autosave() {
        autosave(withDelegate: nil, didAutosave: nil, contextInfo: nil)
    }
}

extension NSDocument.ChangeType {
    static let done = changeDone
}

class OSDocument: NSDocument {
    init(fileURL: URL) {
        super.init()
        self.fileURL = fileURL
    }

    override class var autosavesInPlace: Bool { true }

    override nonisolated func read(from url: URL, ofType typeName: String) throws {
        let fileWrapper = try FileWrapper(url: url, options: .immediate)
        guard fileWrapper.isDirectory else {
            throw OSDocumentError.unknownFileFormat
        }
        try read(from: fileWrapper, ofType: typeName)
    }

    override nonisolated func read(from _: Data, ofType _: String) throws {
        throw OSDocumentError.unknownFileFormat
    }
}

#endif
