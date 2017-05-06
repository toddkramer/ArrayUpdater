# ArrayUpdater

[![Build Status](https://travis-ci.org/toddkramer/ArrayUpdater.svg?branch=master)](https://travis-ci.org/toddkramer/ArrayUpdater) ![CocoaPods Version](https://cocoapod-badges.herokuapp.com/v/ArrayUpdater/badge.png) [![Swift](https://img.shields.io/badge/swift-3-orange.svg?style=flat)](https://developer.apple.com/swift/) ![Platform](https://cocoapod-badges.herokuapp.com/p/ArrayUpdater/badge.png) [![Swift Package Manager compatible](https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat)](https://github.com/apple/swift-package-manager) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

- [Overview](#overview)
- [Usage](#usage)
    - [Serialization](#serialization)
    - [Archiving](#archiving)
    - [Caching](#caching)
- [Installation](#installation)


## Overview

ArrayUpdater is a framework for calculating the insertions, deletions, and reloads needed to update one array to another. Its main use case is to simply the process of updating table and collection views when the data they are presenting changes. The framework returns a struct containing the required insertions, deletions, and reloads, as well as a convenience function to map them to index paths. These index paths can then be used directly in begin/end updates calls (table views) or performBatchUpdates calls (collection views).

## Usage

### Protocol Requirements

*Code*

```swift
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
```

*Explanation*

In order for ArrayUpdater to calculate insertions and deletions, types must conform to the `Equatable` protocol. However, the framework also needs some way to know when an object or value is equal but updated in a meaningful way (reloads).

ArrayUpdater provides the `Distinguishable` protocol for this, which conforms to `Equatable`. Distinguishable has one requirement, that types define what it means for two instances to "match". In the above example which models a national park, two `Park` instances are considered equal if their ids are equal, while they match if their names are equal.

### Updating Arrays

*Code*

```swift
let arches = Park(id: "NPS01", name: "Arches")
let grandCanyon = Park(id: "NPS02", name: "Grand Canyon")
let greatSmoky = Park(id: "NPS03", name: "Great Smoky Mountains")
let greatSmoky2 = Park(id: "NPS03", name: "Great Smokies")
let yosemite = Park(id: "NPS04", name: "Yosemite")
let zion = Park(id: "NPS05", name: "Zion")

let parks1 = [arches, greatSmoky, yosemite, zion]
let parks2 = [zion, grandCanyon, greatSmoky2, yosemite, arches]

let update = parks1.update(to: parks2)
print(update)
```

*Output*

```
▿ Update
  ▿ reloads : 1 element
    - 0 : 1
  ▿ deletions : 2 elements
    - 0 : 0
    - 1 : 3
  ▿ insertions : 3 elements
    - 0 : 0
    - 1 : 1
    - 2 : 4
```

*Explanation*

Table and collection views perform updates in a certain order, with reloads and deletions occurring before insertions. Therefore, in the above example, let's start with the first array and see how we get to the second:

1. We have one reload at index 1. "greatSmoky" and "greatSmoky2" are equal because their ids are equal, but their names do not match, so this item needs to be reloaded. Since reloads and deletions happen before insertions, this reload happens with respect to its index in the first array, which is 1.
2. We have two deletions, at indices 0 and 3. Again, deletions occur before insertions. In our example "arches" and "zion" have changed position, and therefore need to be deleted before being reinserted at their new positions.
3. At this point our array is `[greatSmoky2, yosemite]`. In order to get to `parks2`, we need to insert "zion", "grandCanyon", and "arches" at indices 0, 1, and 4, respectively.

For more information, see the section **Ordering of Operations and Index Paths** in the Apple documentation [here](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/TableView_iPhone/ManageInsertDeleteRow/ManageInsertDeleteRow.html).

### Table & Collection Views

*Code*

```swift
parks = parks1
let update = parks1.update(to: parks2)
parks = parks2

let reloads = update.reloads.indexPaths(inSection: 0)
let deletions = update.deletions.indexPaths(inSection: 0)
let insertions = update.insertions.indexPaths(inSection: 0)

//Table View
tableView.beginUpdates()
tableView.reloadRows(at: reloads, with: .automatic)
tableView.deleteRows(at: deletions, with: .automatic)
tableView.insertRows(at: insertions, with: .automatic)
tableView.endUpdates()

//Collection View
collectionView.performBatchUpdates({ 
    self.collectionView.reloadItems(at: reloads)
    self.collectionView.deleteItems(at: deletions)
    self.collectionView.insertItems(at: insertions)
}, completion: nil)
```

*Explanation*

The `parks` variable represents our data source and is set initially to the original data, `parks1`. ArrayUpdater then calculates the updates, and `parks` is set to `parks2` *before* the table or collection view updates begin. Table / collection view updates must happen after the underlying data source has been updated.

ArrayUpdater provides a convenience function for converting Int arrays (the reload, deletion, or insertion indices) to index paths. It includes a section parameter to support data sources with multiple sections. Here the data source only has one section, so the update indices are converted to their corresponding index paths in section 0.

### Example Data Source

*Code*

```swift
class ParksTableViewDataSource: NSObject, UITableViewDataSource {

    private(set) var parks: [Park]

    init(parks: [Park]) {
        self.parks = parks
    }

    func update(with parks: [Park]) -> Update {
        let update = self.parks.update(to: parks)
        self.parks = parks
        return update
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return parks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ParkCell")!
        let park = parks[indexPath.row]
        cell.textLabel?.text = park.name
        
        return cell
    }

}
```

*Explanation*

The above is an example of how you might implement a table view data source using ArrayUpdater. The key part is the "update:with" function, which returns an `Update` value containing the required reloads, deletions, and insertions. The function simply calculates the updates, replaces the underlying data, and returns the `Update` value. Then the table view can animate the updates as described in **Table & Collection Views**.

## Installation

> _Note:_ ArrayUpdater requires Swift 3 (and [Xcode][] 8) or greater.
>
> Targets using ArrayUpdater must support embedded Swift frameworks.

[Xcode]: https://developer.apple.com/xcode/downloads/

### Swift Package Manager

[Swift Package Manager](https://github.com/apple/swift-package-manager) is Apple's
official package manager for Swift frameworks. To install with Swift Package
Manager:

1. Add ArrayUpdater to your Package.swift file:

    ```
    import PackageDescription

    let package = Package(
        name: "MyAppTarget",
        dependencies: [
            .Package(url: "https://github.com/toddkramer/ArrayUpdater",
                     majorVersion: 1, minor: 2)
        ]
    )
    ```

2. Run `swift build`.

3. Generate Xcode project:

    ```
    swift package generate-xcodeproj
    ```


### Carthage

[Carthage][] is a decentralized dependency manager for Cocoa projects. To
install ArrayUpdater with Carthage:

 1. Make sure Carthage is [installed][Carthage Installation].

 2. Add ArrayUpdater to your Cartfile:

    ```
    github "toddkramer/ArrayUpdater" ~> 1.2.0
    ```

 3. Run `carthage update` and [add the appropriate framework][Carthage Usage].


[Carthage]: https://github.com/Carthage/Carthage
[Carthage Installation]: https://github.com/Carthage/Carthage#installing-carthage
[Carthage Usage]: https://github.com/Carthage/Carthage#adding-frameworks-to-an-application


### CocoaPods

[CocoaPods][] is a centralized dependency manager for Cocoa projects. To install
ArrayUpdater with CocoaPods:

 1. Make sure the latest version of CocoaPods is [installed](https://guides.cocoapods.org/using/getting-started.html#getting-started).


 2. Add ArrayUpdater to your Podfile:

    ``` ruby
    use_frameworks!

    pod 'ArrayUpdater', '~> 1.2.0'
    ```

 3. Run `pod install`.

[CocoaPods]: https://cocoapods.org

