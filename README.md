# SwiftLog

## Introduction

This package contains leveled logging routines for Swift. Formerly a component of https://github.com/mlavergn/swiftutil, it was long overdue to graduate this component into it's own package since it's a fundmental part of my apps.

The goals, in order importance, are:

* Performance
    Speed, speed, and most importantly speed

* Minimal memory overhead
    Maximum memory overhead of 1Kb

* Standalone
    Absolutely no external dependency chain

* Simplicity
    S

## Dependencies

* This package assumes Swift 4.0 syntax
* Assumptions are iOS 10.x / macOS 10.12.x, but it may work on earlier revs.

The are no external dependencies beyond Apple's Frameworks. So this is somewhat platform independent, so long as that platform is one of Apple's.

## Installation

```bash
make
```

## Example

```swift
Log.configure(.debug, .STDOUT)
Log.debug("debug")
Log.info("info")
Log.warn("warning")
Log.error("error")
```
