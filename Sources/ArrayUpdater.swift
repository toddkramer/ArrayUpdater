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

public protocol Distinguishable: Equatable {
    func matches(_ other: Self) -> Bool
}

extension Distinguishable {

    public func matches(_ other: Self) -> Bool {
        return self == other
    }

}

public extension Sequence where Iterator.Element == Int {

    public func indexPaths(inSection section: Int) -> [IndexPath] {
        return map { IndexPath(item: $0, section: section) }
    }

}

public struct Update {
    public internal(set) var insertions = [Int]()
    public internal(set) var deletions = [Int]()
    public internal(set) var reloads = [Int]()

    public enum Step {
        case insert(Int)
        case delete(Int)
        case reload(Int)
    }
}

func ==(lhs: Update, rhs: Update) -> Bool {
    return lhs.insertions == rhs.insertions &&
        lhs.deletions == rhs.deletions &&
        lhs.reloads == rhs.reloads
}

func + (lhs: Update, rhs: Update.Step) -> Update {
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

public struct ViewUpdate {

    public internal(set) var insertions = [IndexPath]()
    public internal(set) var deletions = [IndexPath]()
    public internal(set) var reloads = [IndexPath]()

    public init() {
        self.insertions = [IndexPath]()
        self.deletions = [IndexPath]()
        self.reloads = [IndexPath]()
    }

    public init(update: Update, section: Int) {
        self.insertions = update.insertions.indexPaths(inSection: section)
        self.deletions = update.deletions.indexPaths(inSection: section)
        self.reloads = update.reloads.indexPaths(inSection: section)
    }

    public mutating func append(update: Update, inSection section: Int) {
        insertions += update.insertions.indexPaths(inSection: section)
        deletions += update.deletions.indexPaths(inSection: section)
        reloads += update.reloads.indexPaths(inSection: section)
    }

}

public func += (left: inout ViewUpdate, right: ViewUpdate) {
    left.insertions += right.insertions
    left.deletions += right.deletions
    left.reloads += right.reloads
}

public extension Array where Element: Distinguishable {

    public func update(to other: [Element]) -> Update {
        let comparison = SequenceComparison(self, other)
        return comparison.generateUpdate(count, other.count)
    }

}

struct SequenceComparison<T: Distinguishable> {

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
                } else if x[i - 1] == y[j - 1] {
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

    func generateUpdate(_ i: Int, _ j: Int) -> Update {
        if i == 0 && j == 0 {
            return Update()
        } else if j > 0 && table[i][j] == table[i][j - 1] {
            return generateUpdate(i, j - 1) + .insert(j - 1)
        } else if i > 0 && table[i][j] == table[i - 1][j] {
            return generateUpdate(i - 1, j) + .delete(i - 1)
        } else if !x[i - 1].matches(y[j - 1]) {
            return generateUpdate(i - 1, j - 1) + .reload(i - 1)
        } else {
            return generateUpdate(i - 1, j - 1)
        }
    }

}
