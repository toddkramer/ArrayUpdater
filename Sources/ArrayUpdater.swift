//
//  ArrayUpdater.swift
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

import Foundation

#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

public extension Sequence where Iterator.Element == Int {

    public func indexPaths(inSection section: Int) -> [IndexPath] {
        return map { IndexPath(item: $0, section: section) }
    }

}

public struct IndexUpdate: Equatable {

    public internal(set) var insertions = [Int]()
    public internal(set) var deletions = [Int]()
    public internal(set) var reloads = [Int]()

    public enum Step {
        case insert(Int)
        case delete(Int)
        case reload(Int)
    }

    public init(insertions: [Int] = [], deletions: [Int] = [], reloads: [Int] = []) {
        self.insertions = insertions
        self.deletions = deletions
        self.reloads = reloads
    }

    public var hasChanges: Bool {
        return !(insertions.isEmpty && deletions.isEmpty && reloads.isEmpty)
    }

}

func +(lhs: IndexUpdate, rhs: IndexUpdate.Step) -> IndexUpdate {
    var update = lhs
    switch rhs {
    case .insert(let i):
        update.insertions.append(i)
    case .delete(let i):
        update.deletions.append(i)
    case .reload(let i):
        update.reloads.append(i)
    }
    return update
}

public struct ViewUpdate: Equatable {

    public internal(set) var insertions = [IndexPath]()
    public internal(set) var deletions = [IndexPath]()
    public internal(set) var reloads = [IndexPath]()

    public static var noUpdate: ViewUpdate { return .init() }

    public var inverse: ViewUpdate {
        return ViewUpdate(insertions: deletions, deletions: insertions, reloads: reloads)
    }

    public init(insertions: [IndexPath] = [], deletions: [IndexPath] = [], reloads: [IndexPath] = []) {
        self.insertions = insertions
        self.deletions = deletions
        self.reloads = reloads
    }

    public init(update: IndexUpdate, section: Int) {
        self.insertions = update.insertions.indexPaths(inSection: section)
        self.deletions = update.deletions.indexPaths(inSection: section)
        self.reloads = update.reloads.indexPaths(inSection: section)
    }

    public mutating func append(update: IndexUpdate, inSection section: Int) {
        let newInsertions = update.insertions.indexPaths(inSection: section)
        let newDeletions = update.deletions.indexPaths(inSection: section)
        let newReloads = update.reloads.indexPaths(inSection: section)
        let newUpdate = ViewUpdate(insertions: newInsertions, deletions: newDeletions, reloads: newReloads)
        self += newUpdate
    }

}

public func += (left: inout ViewUpdate, right: ViewUpdate) {
    left.insertions = Array(Set(left.insertions + right.insertions)).sorted()
    left.deletions = Array(Set(left.deletions + right.deletions)).sorted()
    left.reloads = Array(Set(left.reloads + right.reloads)).sorted()
}

public extension Array where Element: Updatable {

    public func update(to other: [Element]) -> IndexUpdate {
        let comparison = SequenceComparison(self, other)
        return comparison.generateUpdate(count, other.count)
    }

}

struct SequenceComparison<T: Updatable> {

    typealias Table = [[Int]]

    let table: Table
    let x: [T]
    let y: [T]

    private static func buildTable(_ x: [T], _ y: [T]) -> Table {
        let n = x.count, m = y.count
        var table = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        for i in 0...n {
            for j in 0...m {
                if (i == 0 || j == 0) {
                    table[i][j] = 0
                } else if x[i - 1].id == y[j - 1].id {
                    table[i][j] = table[i - 1][j - 1] + 1
                } else {
                    table[i][j] = max(table[i - 1][j], table[i][j - 1])
                }
            }
        }
        return table
    }

    init(_ x: [T], _ y: [T]) {
        self.table = SequenceComparison.buildTable(x, y)
        self.x = x
        self.y = y
    }

    func generateUpdate(_ i: Int, _ j: Int) -> IndexUpdate {
        if i == 0 && j == 0 {
            return IndexUpdate()
        } else if j > 0 && table[i][j] == table[i][j - 1] {
            return generateUpdate(i, j - 1) + .insert(j - 1)
        } else if i > 0 && table[i][j] == table[i - 1][j] {
            return generateUpdate(i - 1, j) + .delete(i - 1)
        } else if x[i - 1] != y[j - 1] {
            return generateUpdate(i - 1, j - 1) + .reload(i - 1)
        } else {
            return generateUpdate(i - 1, j - 1)
        }
    }

}
