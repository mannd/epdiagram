//
//  Sandbox.swift
//  EP Diagram
//
//  Created by David Mann on 5/19/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import Foundation

enum Sandbox {
    static func storeDirectoryBookmark(from url: URL) {
        guard url.hasDirectoryPath else {
            print("URL not a directory")
            return
        }
        #if targetEnvironment(macCatalyst)
        let bookmarkOptions: URL.BookmarkCreationOptions = [.withSecurityScope, .minimalBookmark]
        #else
        let bookmarkOptions: URL.BookmarkCreationOptions = [.minimalBookmark]
        #endif
        let key = getAccessDirectoryKey(for: url)
        if let bookmark = try? url.bookmarkData(options: bookmarkOptions, includingResourceValuesForKeys: nil, relativeTo: nil) {
            UserDefaults.standard.setValue(bookmark, forKey: key)
            print("seeting bookmark in UserDefaults")
        } else {
            print("Could not create directory bookmark.")
        }
    }

    /// Get the persisted directory location via bookmarks for a file url
    /// - Parameter url: The URL of the file to be opened.
    /// - Returns: The persistent URL of the directory containing that file.
    static func getPersistentDirectoryURL(forFileURL url: URL) -> URL? {
        if let bookmark = getDirectoryBookmarkData(url: url) {
            if let persistentURL = getPersistentDirectoryURL(forBookmarkData: bookmark, directoryURL: url) {
                return persistentURL
            } else {
                print("Could not retrieve bookmark")
                return nil
            }
        }
        else {
            print("Could not get bookmark from UserDefaults")
            return nil
        }
    }

    static func getPersistentDirectoryURL(forBookmarkData bookmark: Data, directoryURL directory: URL) -> URL? {
        #if targetEnvironment(macCatalyst)
        let bookmarkOptions: URL.BookmarkResolutionOptions = [.withSecurityScope]
        #else
        let bookmarkOptions: URL.BookmarkResolutionOptions = []
        #endif
        var bookmarkDataIsStale: Bool = false
        if let urlForBookmark = try? URL(resolvingBookmarkData: bookmark, options: bookmarkOptions, relativeTo: nil, bookmarkDataIsStale: &bookmarkDataIsStale) {
            if bookmarkDataIsStale {
                print("Regenerating stale bookmark")
                storeDirectoryBookmark(from: directory)
                return nil
            } else {
                print("directory urlForBookmark = ", urlForBookmark as Any)
                return urlForBookmark
            }
        } else {
            print("Could not retrieve bookmark")
            return nil
        }
    }

    static func getDirectoryBookmarkData(url: URL) -> Data? {
        print("getDirectoryBookmarkData()")
        let directory = url.deletingLastPathComponent()
        guard directory.hasDirectoryPath else {
            print("Is not a directory path")
            return nil }
        let key = getAccessDirectoryKey(for: directory)
        let value = UserDefaults.standard.value(forKey: key) as? Data
        print("directory value is ", value as Any)
        return value
    }

    private static func getAccessDirectoryKey(for url: URL) -> String {
        return "AccessDirectory:\(url.path)"
    }
}
