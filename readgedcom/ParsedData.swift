//
//  ParsedData.swift
//  readgedcom
//
//  Created by Jim Clarke on 2021-05-04.
//

// A container for the lines of the input (simple Substrings) analysed into
// GEDCOM "records" (DataLines).


import Foundation
//import StringUtilities
import TextFileUtilities


// The things we're extracting from the raw strings (well, Substrings) read from
// the input file.

class DataLine {
    var asRead: String
    var lineNum: Int // starting at 0
    var level: Int
    var tag: String
    var value: String
    var hasBeenRead = false // that is, has been used in constructing the
    // data structures used to produce the eventual output -- see Ancestry.swift

    init(asRead: String, lineNum: Int, level: Int, tag: String, value: String) {
        self.asRead = asRead
        self.lineNum = lineNum
        self.level = level
        self.tag = tag
        self.value = value
    }
}

// The collection of DataLines extracted from the raw input Substrings.

class ParsedData {
    // in
    // let rawLines: [Substring]
    
    // out
    fileprivate(set) var parsedLines = [DataLine]()
    
    // error reporting
    let errors: OutFile
    
    // properties
    var count: Int { parsedLines.count }
    
    init(rawLines: [Substring], errors: OutFile) {
        // self.rawLines = rawLines
        self.errors = errors
        
        parseData(input: rawLines)
        checkData(input: rawLines)
    }
    
    
    // Convert the input, line by line, to DataLines and return the resulting
    // array, reporting problems to errors.
    
    func parseData(input: [Substring]) {        
        // The loop is over the index, not simply the lines, because we need the
        // line number for error messages.
        for i in 0 ..< input.count {
            var line = input[i]
            
            // The line must not be empty.
            if line.isEmpty {
                errors.writeln(i, "empty line")
            }
            
            // level
            var level = -1 // not a valid level
            let pastLevelEnd = line.firstIndex(of: " ") ?? line.endIndex
            if let levelRead = Int(line[line.startIndex ..< pastLevelEnd]) {
                level = levelRead
            }
            else {
                errors.writeln(i, "bad level number")
            }
            if level < 0 {
                errors.writeln(i, "bad level number")
            }
            line = line[line.index(after: pastLevelEnd) ..< line.endIndex]
            
            // tag
            let pastTagEnd = line.firstIndex(of: " ") ?? line.endIndex
            let tag = String(line[..<pastTagEnd])
            
            // value
            var value = ""
            if pastTagEnd < line.endIndex {
                let valueRange = line.index(after: pastTagEnd) ..< line.endIndex
                value = String(line[valueRange])
            }
            
            // Done.
            let dataline = DataLine(
                asRead: String(line),
                lineNum: i,
                level: level,
                tag: tag,
                value: value
            )
            parsedLines.append(dataline)
        }
    }
    
    
    // Discarded check output -- conceivably might be useful again
    
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
    
    
    // Check the data. At least some of these checks are implicit in later work
    // with the forest (of trees) that is the major data structure, but a
    // simple-minded early check helps to preserve programmer self-confidence
    // and sanity.
    //
    // Trouble is indicated by output to errors, not by a return value or a
    // thrown Error.
    
    func checkData(input: [Substring]) {
        
        // Check that the number of lines hasn't changed.
        
        if parsedLines.count != input.count {
            errors.writeln("number of input lines surprisingly varies")
        }
        
        // Check the first and last lines.
        
        let first = parsedLines[0]
        let last = parsedLines[parsedLines.count - 1]
        
        let firstOK = first.level == 0
            && first.tag == "HEAD"
            && first.value == ""
        if !firstOK {
            errors.writeln("first line of input not as expected")
        }
        let lastOK = last.level == 0
            && last.tag == "TRLR"
            && last.value == ""
        if !lastOK {
            errors.writeln("last line of input not as expected")
        }
        
        // Check the internal level values and changes.
        
        for i in 1 ..< parsedLines.count {
            // Levels are non-negative.
            if parsedLines[i].level < 0 {
                errors.writeln(i, "negative level")
            }
            // Levels can jump down by more than 1, but not up. ("It is a fatal
            // error to skip a level." -- GEDCOM standard, Chapter 1.)
            if parsedLines[i].level - parsedLines[i-1].level > 1 {
                errors.writeln(i, "unexpected level jump")
            }
        }
    }
    
    
    // Return the number of DataLines in this ParsedData object that do not have
    // hasBeenRead set. DataLines are not counted that are part of the first
    // two GEDCOM records (HEAD and SUBM) or the last (TRLR).
    //
    // If printUnreadLines is true, unread lines are reported to errors, except
    // in the HEAD, SUBM and TRLR records.
    //
    // Since Ancestry.checkAncestry() includes an unread-record check that
    // prints the unread records, you probably don't want to set
    // printUnreadLines to true unless you're having trouble locating an error.
    
    func countUnread(printUnreadLines: Bool = false) -> Int {
        if parsedLines.count == 0 {
            errors.writeln("countUnread found parsedLines was empty")
            return 0
        }
        
        var lineNum = 0 // zero-based, remember
        
        // The HEAD record
        var line = parsedLines[lineNum]
        if line.level != 0 || line.tag != "HEAD" {
            errors.writeln(lineNum, "unexpected level or tag in \(line.asRead)")
        }
        lineNum += 1
        while lineNum < parsedLines.count && parsedLines[lineNum].level > 0 {
            lineNum += 1
        }

        // The SUBM record
        if lineNum >= parsedLines.count {
            errors.writeln("countUnread ran out of lines before the SUBM record")
            return 0
        }
        line = parsedLines[lineNum]
        if line.level != 0 || line.tag != "@SUBM@" {
            errors.writeln(lineNum, "unexpected level or tag in \(line.asRead)")
        }
        lineNum += 1
        while lineNum < parsedLines.count && parsedLines[lineNum].level > 0 {
            lineNum += 1
        }
        
        // The actual data records
        if lineNum >= parsedLines.count {
            errors.writeln("countUnread ran out of lines before actual data")
            return 0
        }
        line = parsedLines[lineNum]
        if line.level != 0 {
            errors.writeln(lineNum, "unexpected level in \(line.asRead)")
        }
        // Stay on the same line for the first loop iteration.

        // Start counting.
        
        var unreadCount = 0 // will be the value returned

        while lineNum < parsedLines.count {
            line = parsedLines[lineNum]
            if line.level == 0 && line.tag == "TRLR" {
                break
            }
            if !line.hasBeenRead {
                unreadCount += 1
                if printUnreadLines {
                    errors.writeln(lineNum, "line has not been read: \(line.asRead)")
                }
            }
            lineNum += 1
        }
        
        // Check the last record.
        line = parsedLines[lineNum]
        if lineNum != parsedLines.count - 1
            || line.level != 0
            || line.tag != "TRLR"
        {
            errors.writeln("countUnread did not find final TRLR record")
        }
        
        return unreadCount
    }
}
