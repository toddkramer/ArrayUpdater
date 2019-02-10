//
//  ArrayUpdaterTests.swift
//
//  Copyright (c) 2016 Todd Kramer (http://www.tekramer.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import XCTest
import ArrayUpdater

struct Park: Updatable {

    let id: String
    let name: String

}

class ArrayUpdaterTests: XCTestCase {

    struct TestCase {
        let x: [Park]
        let y: [Park]
        let expectedUpdate: IndexUpdate
    }

    let arches = Park(id: "NPS01", name: "Arches")
    let grandCanyon = Park(id: "NPS02", name: "Grand Canyon")
    let greatSmoky = Park(id: "NPS03", name: "Great Smoky Mountains")
    let greatSmoky2 = Park(id: "NPS03", name: "Great Smokies")
    let yosemite = Park(id: "NPS04", name: "Yosemite")
    let zion = Park(id: "NPS05", name: "Zion")

    func testUpdate() {
        let tests = [
            TestCase(x: [arches, grandCanyon, yosemite, zion], y: [grandCanyon, zion], expectedUpdate: IndexUpdate(insertions: [], deletions: [0, 2], reloads: [])),
            TestCase(x: [grandCanyon, zion], y: [arches, grandCanyon, yosemite, zion], expectedUpdate: IndexUpdate(insertions: [0, 2], deletions: [], reloads: [])),
            TestCase(x: [arches, greatSmoky, yosemite, zion], y: [arches, greatSmoky2, yosemite, zion], expectedUpdate: IndexUpdate(insertions: [], deletions: [], reloads: [1])),
            TestCase(x: [arches, greatSmoky, yosemite, zion], y: [zion, grandCanyon, greatSmoky2, yosemite, arches], expectedUpdate: IndexUpdate(insertions: [0, 1, 4], deletions: [0, 3], reloads: [1]))
        ]

        for test in tests {
            let update = test.x.update(to: test.y)
            XCTAssert(update == test.expectedUpdate)
        }
    }

    func testAppendUpdate() {
        var viewUpdate = ViewUpdate()
        let update1 = IndexUpdate(insertions: [], deletions: [0, 2], reloads: [])
        let update2 = IndexUpdate(insertions: [0, 4], deletions: [0, 3], reloads: [1])
        viewUpdate.append(update: update1, inSection: 0)
        viewUpdate.append(update: update2, inSection: 0)
        let expectedIndexUpdate = IndexUpdate(insertions: [0, 4], deletions: [0, 2, 3], reloads: [1])
        let expectedViewUpdate = ViewUpdate(update: expectedIndexUpdate, section: 0)
        XCTAssertEqual(viewUpdate, expectedViewUpdate)
    }

    func testHasChanges() {
        let update1 = IndexUpdate()
        let update2 = IndexUpdate(insertions: [0, 4], deletions: [0, 3], reloads: [1])
        XCTAssertFalse(update1.hasChanges)
        XCTAssertTrue(update2.hasChanges)
    }

    func testInverse() {
        let indexUpdate = IndexUpdate(insertions: [0, 4], deletions: [0, 3], reloads: [1])
        let viewUpdate = ViewUpdate(update: indexUpdate, section: 0)
        let inverse = viewUpdate.inverse
        let expected = ViewUpdate(insertions: viewUpdate.deletions, deletions: viewUpdate.insertions, reloads: viewUpdate.reloads)
        XCTAssertEqual(inverse, expected)
    }

    func testNoUpdate() {
        XCTAssertEqual(ViewUpdate(), .noUpdate)
    }

    func testUpdatableContains() {
        XCTAssertTrue([arches].contains(arches))
    }

}
