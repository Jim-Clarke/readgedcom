//
//  main.swift
//  readgedcom
//
//  Created by Jim Clarke on 2021-04-28.
//

import Foundation
import TextFileUtilities

print("Hello, Genealogical World!")

let hereDir = "/Users/clarke/Documents/computing/src/Swift/readgedcom/"

let myfile = OutFile(hereDir + "runOutput")
myfile.writeln("first output to file")
try myfile.finalize()

let scanner = try OptionScanner("ir")
let usageMessage = "Usage: readgedcom " + scanner.usageString()
print(usageMessage)
let nRead = try scanner.getOpts(CommandLine.arguments)
for o in scanner.allOptions where o.isSet {
    switch o.optionChar {
    case "i": print("It's an 'i'!")
    case "r": print("It's an 'r'!")
    default:
        // You won't reach here, because if the arguments refer to an
        // unrecognized option, then getOpts() has already thrown an
        // OptionError.failedGet. But Swift wants a default.
        print(usageMessage)
        exit(1)
    }
}
