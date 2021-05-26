//
//  main.swift
//  readgedcom
//
//  Created by Jim Clarke on 2021-04-28.
//

import Foundation
import StringUtilities
import TextFileUtilities


// Work through the command-line arguments, reacting to the options, and return
// (1) the name of the file to work with, and (2, 3) the results of reading the
// options.

func readLineArgs() -> (String, Bool, Bool) {
    let args = CommandLine.arguments
    let programName = URL(fileURLWithPath: nameToPath(fileName: args[0]))
        .lastPathComponent

    // Set up option scanner.
    let scanner = try! OptionScanner("is")

    // Prepare for usage errors.
    let usageMessage = "Usage: " + programName + " " + scanner.usageString()
        + " gedcomfile"
    func usage() {
        printerr(usageMessage)
        exit(1)
    }

    // Read options.
    var nRead: Int? // arg index after last option
    do {
        nRead = try scanner.getOpts(args)
        if nRead != args.count - 1 {
            usage()
        }
    }
    catch {
        usage()
    }

    // The file name is the last argument -- the one non-option argument.
    let infileName = args[nRead!] // not args.last, because who knows?
    
    var showPersonIDs = true // Print personIDs as well as names?
    var sortReport = false // Sort the output report by name?
    
    for o in scanner.allOptions where o.isSet {
        switch o.optionChar {
        case "i": showPersonIDs = false
        case "s": sortReport = true
        default:
            usage()
        }
    }

    // All done
    return (infileName, showPersonIDs, sortReport)
}


// Input file and some output controls, read from the command line

var infileName: String
var showPersonIDs: Bool
var sortReport: Bool

(infileName, showPersonIDs, sortReport) = readLineArgs()


// Output files

// The actual desired output goes to reportfile (which would be a wrapper for
// stdout in ordinary use), while errorsfile (stderr) gets both actual errors
// and a summary of lines read, people extracted, etc.
//
// Running in Xcode -- see below -- both are actual files.
var reportfile: OutFile
var errorsfile: OutFile

// ------------------------------------
// Comment out the assignments in Section A or Section B (not both!).
// ------------------------------------

// SECTION A: Running in Xcode

// Running in Xcode, you need to set the run scheme to provide
//  - any desired options
//  - the input file name, relative to the execution directory
// The execution directory "hereDir" is the directory for the Xcode project.
// Mine is shown. Replace it with yours!

let hereDir = "/Users/clarke/Documents/computing/src/Swift/readgedcom/"
reportfile = OutFile(hereDir + "dev.out")
errorsfile = OutFile(hereDir + "dev.err")

// ------------------------------------

// SECTION B: Running in normal use (and not in Xcode)

// You don't need hereDir.
//reportfile = StreamedOutFile("report", stream: stdoutStream)
//errorsfile = StreamedOutFile("errors", stream: stderrStream)

// ------------------------------------


// Prepare to report on errors and summarize results.
var summary = ""

// Start activity summary
let now = Date()
let formatter = DateFormatter()
formatter.timeZone = TimeZone.current
formatter.dateFormat = "yyy-MM-dd HH:mm:ss"
summary += "Running at \(formatter.string(from: now))\n"
summary += "Input file: \(infileName)\n"


// Read the input.
var rawData: [Substring]
do {
    rawData = try InFile(hereDir + infileName).read()
}
catch FileError.failedRead(let msg) {
    errorsfile.writeln(msg)
    exit(1)
}
summary += "Lines read: \(rawData.count)\n"

// Break the input lines into parts, as DataLine values.
let data = ParsedData(rawLines: rawData, errors: errorsfile)
summary += "Lines parsed: \(data.count)\n"

// Build the forest of data.
let dataForest = DataForest(data: data, errors: errorsfile)
summary += "Records built: \(dataForest.roots.count)\n"

// Build the actual family "tree".
let ancestry = Ancestry(dataForest, errors: errorsfile)
summary += "Lines ignored: \(ancestry.unusedLineCount)\n"
summary += "Persons: \(ancestry.people.count)\n"
summary += "Families: \(ancestry.families.count)\n"
summary += "Notes: \(ancestry.notes.count)\n"
summary += "\"Lines ignored\" should be 0.\n"
summary += "\"Records built\" should be Persons + Families + Notes + 3.\n"

// Produce the report.
let reporter = Reporter(ancestry, infileName, showPersonIDs, sortReport,
    reportFile: reportfile, errors: errorsfile)
reporter.report()

// Summarize.
if !errorsfile.hasBeenUsed {
    errorsfile.writeln("No errors were reported during processing\n")
}
else {
    errorsfile.writeln("\nEnd of error reports\n")
}
errorsfile.writeln("Summary of results:\n")
errorsfile.writeln(summary)

// Flush any output files with unwritten output.
try OutFile.finalizeAll()
