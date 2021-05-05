//
//  ParseData.swift
//  readgedcom
//
//  Created by Jim Clarke on 2021-05-04.
//

// Parse each line of the input into a GEDCOM "record".


import Foundation
//import StringUtilities
import TextFileUtilities

// Each input line is parsed from a Substring into a DataLine.

struct DataLine {
    var asRead: String
    var lineNum: Int // starting at 0
    var level: Int
    var tag: String
    var value: String
    var hasBeenRead = false // that is, has been used in constructing the
    // data structures used to produce the eventual output
}

// Convert the input, line by line, to DataLines and return the resulting array,
// reporting problems to errorsFile.

func parseData(_ lines: [Substring], errorsfile errors: inout OutFile)
        -> [DataLine] {
    var result = [DataLine]()
    
    // Take the lines apart.
    for i in 0 ..< lines.count {
        let line = String(lines[i])
        
        // The line must not be empty.
        if line.count == 0 {
            errors.writeln(i, "empty line")
        }
        
        // "lineBeingDissected"
        var lineBD = line[line.startIndex ..< line.endIndex]
        
        // level
        var level = -1 // not a valid level
        let pastLevelEnd = lineBD.firstIndex(of: " ") ?? lineBD.endIndex
        if let levelRead = Int(lineBD[lineBD.startIndex ..< pastLevelEnd]) {
            level = levelRead
        }
        else {
            errors.writeln(i, "bad level number")
        }
        if level < 0 {
            errors.writeln(i, "bad level number")
        }
        lineBD = lineBD[lineBD.index(after: pastLevelEnd) ..< lineBD.endIndex]
        
        // tag
        let pastTagEnd = lineBD.firstIndex(of: " ") ?? lineBD.endIndex
        let tag = String(lineBD[..<pastTagEnd])
        
        // value
        var value = ""
        if pastTagEnd < lineBD.endIndex {
            let valueRange = lineBD.index(after: pastTagEnd)
                ..< lineBD.endIndex
            value = String(lineBD[valueRange])
        }
        
        // Done.
        let dataline = DataLine(
            asRead: line, lineNum: i, level: level, tag: tag, value: value)
        result.append(dataline)
    }
    
    return result
}


//// Break the input lines into parts, as DataLine values.
//let data = parseData(rawData, errorsFile: &errorsfile)

// Write the input data in case the user wants to look at them.
// var lineNum = 1
// for line in data {
//     let echoLine =
//         "line \(lineNum): level \(line.level) tag::\(line.tag):: value::\(line.value)::"
//     parsedinputfile.writeln(echoLine)
//     lineNum += 1
// }

// Write the tags
// for line in data {
//     tagsfile.writeln(line.tag)
// }


// Check the data. At least some of these checks are implicit in later work with
// the forest (of trees) that is the major data structure, but a simple-minded
// early check helps to preserve programmer self-confidence and sanity.
//
// Trouble is indicated by output to errorsFile, not by a return value.

func checkData(_ data: [DataLine], errorsfile errors: inout OutFile) {

    let NUMBER_OF_INPUT_LINES = data.count
    let first = data[0]
    let last = data[NUMBER_OF_INPUT_LINES - 1]
    
    if NUMBER_OF_INPUT_LINES != rawData.count {
        errorsfile.writeln("number of input lines surprisingly varies")
    }
    
    // Check the first and last lines.
    
    let firstOK = first.level == 0
        && first.tag == "HEAD"
        && first.value == ""
    if !firstOK {
        errorsfile.writeln("first line of input not as expected")
    }
    let lastOK = last.level == 0
        && last.tag == "TRLR"
        && last.value == ""
    if !lastOK {
        errorsfile.writeln("last line of input not as expected")
    }
    
    // Check the internal level values and changes.
    
    for i in 1 ..< NUMBER_OF_INPUT_LINES {
        // Levels are non-negative.
        if data[i].level < 0 {
            errorsfile.writeln(i, "negative level")
        }
        // Levels can jump down by more than 1, but not up. ("It is a fatal
        // error to skip a level." -- GEDCOM standard, Chapter 1.)
        if data[i].level - data[i-1].level > 1 {
            errorsfile.writeln(i, "unexpected level jump")
        }
    }
}
