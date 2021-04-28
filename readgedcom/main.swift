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
myfile.writeln("first output to file")
try myfile.finalize()

let scanner = try OptionScanner("ir")
let usageMessage = "Usage: readgedcom " + scanner.usageString()
print(usageMessage)
