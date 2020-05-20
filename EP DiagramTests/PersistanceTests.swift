//
//  PersistanceTests.swift
//  EP DiagramTests
//
//  Created by David Mann on 5/19/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import XCTest
@testable import EP_Diagram

class PersistanceTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testGetURL() {
        // these aren't tests, just used for debuggin
        var url = Persistance.getURL(for: .documents)
        P("url.documents = \(String(describing: url))")
        url = Persistance.getURL(for: .cache)
        P("url.cache = \(String(describing: url))")
        url = Persistance.getURL(for: .applicationSupport)
        P("url.applicationSupport = \(String(describing: url))")
        let s = "This is a test"
        try! Persistance.store(s, to: .documents, withFileName: "test1")
        let returnedS: String?  = Persistance.retrieve("test1", from: .documents, as: String.self)
        XCTAssertEqual(s, returnedS!)
    }

}
