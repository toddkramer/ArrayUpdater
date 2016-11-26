//
//  ArrayUpdaterTests.swift
//  ArrayUpdaterTests
//
//  Created by Todd Kramer on 11/25/16.
//
//

import XCTest
@testable import ArrayUpdater

struct Park: Distinguishable {
    let id: String
    let name: String

    func matches(_ other: Park) -> Bool {
        return name == other.name
    }
}

func ==(lhs: Park, rhs: Park) -> Bool {
    return lhs.id == rhs.id
}

class ArrayUpdaterTests: XCTestCase {

    struct TestCase {
        let x: [Park]
        let y: [Park]
        let expectedUpdate: Update
    }

    let arches = Park(id: "NPS01", name: "Arches")
    let grandCanyon = Park(id: "NPS02", name: "Grand Canyon")
    let greatSmoky = Park(id: "NPS03", name: "Great Smoky Mountains")
    let greatSmoky2 = Park(id: "NPS03", name: "Great Smokies")
    let yosemite = Park(id: "NPS04", name: "Yosemite")
    let zion = Park(id: "NPS05", name: "Zion")

    func testUpdate() {
        let tests = [
            TestCase(x: [arches, grandCanyon, yosemite, zion], y: [grandCanyon, zion], expectedUpdate: Update(insertions: [], deletions: [0, 2], reloads: [])),
            TestCase(x: [grandCanyon, zion], y: [arches, grandCanyon, yosemite, zion], expectedUpdate: Update(insertions: [0, 2], deletions: [], reloads: [])),
            TestCase(x: [arches, greatSmoky, yosemite, zion], y: [arches, greatSmoky2, yosemite, zion], expectedUpdate: Update(insertions: [], deletions: [], reloads: [1])),
            TestCase(x: [arches, greatSmoky, yosemite, zion], y: [zion, grandCanyon, greatSmoky2, yosemite, arches], expectedUpdate: Update(insertions: [0, 1, 4], deletions: [0, 3], reloads: [1]))
        ]

        for test in tests {
            let update = test.x.update(to: test.y)
            XCTAssert(update == test.expectedUpdate)
        }
    }

}
