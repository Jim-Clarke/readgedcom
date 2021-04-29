//
//  main.swift
//  readgedcom
//
//  Created by Jim Clarke on 2021-04-28.
//

import Foundation
import StringUtilities
import TextFileUtilities

print("Hello, Genealogical World!")

let hereDir = "/Users/clarke/Documents/computing/src/Swift/readgedcom/"

let myfile = OutFile(hereDir + "runOutput")
let now = Date()
myfile.writeln("output to file at \(now)")
try myfile.finalize()

let scanner = try OptionScanner("ir")
let usageMessage = "Usage: readgedcom " + scanner.usageString()
print(usageMessage)
let nRead = try scanner.getOpts(CommandLine.arguments)
print("args read: \(nRead)")
for o in scanner.allOptions where o.isSet {
    switch o.optionChar {
    case "i": print("It's an 'i'!")
    case "r": print("It's an 'r'!")
    default:
        print(usageMessage)
        exit(1)
    }
}
