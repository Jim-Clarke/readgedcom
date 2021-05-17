//
//  main.swift
//  readgedcom
//
//  Created by Jim Clarke on 2021-04-28.
//

import Foundation
import StringUtilities
import TextFileUtilities

enum GEDCOMerror: Error {
    case badArgs(_ msg: String) // don't need this so far
}

print("Here we go!")

// These definitions need to go away when we're done running in Xcode.
let hereDir = "/Users/clarke/Documents/computing/src/Swift/readgedcom/"
let outFile = hereDir + "dev.out"
let sortedOutFile = hereDir + "dev.out.sorted"
let errFile = hereDir + "dev.err"


// Work through the command-line arguments, reacting to the option, and return
// (1) the name of the file to work with, and (2) the results of reading the
// options.
//
// This function's design purpose is just segregation of these operations.

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

    // Read the one non-option argument.
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

    let infileName = args[nRead!] // not args.last, because who knows?

    // All done
    return (infileName, showPersonIDs, sortReport)
}

// Input file and some output controls, read from the command line

var infileName: String
var showPersonIDs: Bool
var sortReport: Bool

(infileName, showPersonIDs, sortReport) = readLineArgs()


// Output files

var reportfile: OutFile
var sortedreportfile: OutFile
var errorsfile: OutFile

// In the end, output should go to stdout, but while we're running in Xcode,
// we'll send it to named files -- two of them, or maybe three, depending on how
// much option testing we want.

//reportfile = StreamedOutFile("report", stream: stdoutStream)
reportfile = OutFile(outFile)
//sortedreportfile = StreamedOutFile("sortedreport", stream: stdoutStream)
sortedreportfile = OutFile(sortedOutFile)

// Actual, immediately fatal errors will be reported using printerr(). A summary
// of activities is reported through errorsfile, leaving reportfile (which is
// currently stdout) for output of the wanted information.

//errorsfile = StreamedOutFile("errors", stream: stderrStream)
errorsfile = OutFile(errFile)

// Prepare to report on errors and summarize results.
var summary = ""

// Start activity summary
let now = Date()
let formatter = DateFormatter()
formatter.timeZone = TimeZone.current
formatter.dateFormat = "yyy-MM-dd HH:mm:ss"
summary += "Running program at \(formatter.string(from: now))\n"
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

// Produce the report.
let reporter = Reporter(ancestry, infileName, showPersonIDs, sortReport,
    reportFile: reportfile, errors: errorsfile)
reporter.report()

// This isn't going to work like this!
if !errorsfile.hasBeenUsed {
    errorsfile.writeln("No errors were reported during processing\n")
}
else {
    errorsfile.writeln("\nEnd of error reports\n")
}
errorsfile.writeln("Summary of results:\n")
errorsfile.writeln(summary)


try OutFile.finalizeAll()
