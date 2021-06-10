//
//  main.swift
//  readgedcom
//
//  Created by Jim Clarke on 2021-04-28.

// Versions: Swift 5.4, macOS 11.4, 12.5

// Hello, dear reader of my code, and welcome aboard! The ride is bound to be a
// little bumpy, but maybe these tips will help:
//
// - The purpose of the program is to read a GEDCOM (genealogical export format)
//   and produce two products:
//   1) a textual representation, perhaps for showing to other family members;
//   2) "error" reports where the input file doesn't match current GEDCOM rules,
//      or where the program or the data are faulty. Specifically, the program
//      checks to ensure it has looked at all the input data.
//
// - The program is guaranteed not to cover all of the GEDCOM standard. If you
//   want to expand its coverage, the GEDCOM document may help:
//      https://www.gedcom.org/gedcom.html
//   You want version 5.5.5.
//
// - As you can see from the end of this "main.swift" file, data structures are
//   defined and actions are taken in this order:
//      main.swift: preliminaries
//      ParsedData: breaking the lines of input into meaningful chunks
//      DataForest: making a tree (not a family tree!) for each GEDCOM record
//      Ancestry: extracting the people and their families from the data trees
//      Reporter: "printing" the output
//
// - This was my first non-trivial Swift program, as you'll probably notice.
//   Watch for design choices influenced by C or Java.
//
//   Feel free to contact me through Github, and I'll see if I can remember what
//   I did.
//
// -- Jim Clarke, June 2021


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


// Input file name and some output controls, read from the command line

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
// Xcode knows your home directory via its environment variable "HOME", but you
// have to tell it the path relative to your home. You could define another
// environment variable to do that, but I've just hard-wired it.
//
// Replace my path with yours!

let hereDir = ProcessInfo.processInfo.environment["HOME"]!
    + "/Documents/computing/src/Swift/readgedcom/"

let infile = InFile(hereDir + infileName)

reportfile = OutFile(hereDir + "dev.out")
errorsfile = OutFile(hereDir + "dev.err")

// ------------------------------------

// SECTION B: Running in normal use (and not in Xcode)

// You don't need hereDir.

//let infile = InFile(infileName)
//
//reportfile = StreamedOutFile("report", stream: stdoutStream)
//errorsfile = StreamedOutFile("errors", stream: stderrStream)

// ------------------------------------


// Prepare to report on errors and summarize results.
var summary = ""
func smry(_ msg: String) { summary += msg + "\n" }

// Start activity summary.
let now = Date()
let formatter = DateFormatter()
formatter.timeZone = TimeZone.current
formatter.dateFormat = "yyy-MM-dd HH:mm:ss"
smry("Running at \(formatter.string(from: now))")
smry("Input file: \(infileName)")


// Read the input.
smry("\nReading data, then building data structures ...")
var rawData: [Substring]
do {
    rawData = try infile.read()
}
catch FileError.failedRead(let msg) {
    errorsfile.writeln(msg)
    exit(1)
}
smry("Lines read: \(rawData.count)")

// Break the input lines into parts, as DataLine values.
let data = ParsedData(rawLines: rawData, errors: errorsfile)
smry("Lines parsed: \(data.count) [should be same as lines read]")
smry("Parsed lines not read: \(data.countUnread())"
    + " [should be somewhat fewer than lines read]")

// Build the forest of data.
let dataForest = DataForest(data: data, errors: errorsfile)
let nRoots = dataForest.roots.count
smry("Records (tree roots) built: \(nRoots)")
smry("Tree nodes not read: \(dataForest.countUnread())"
    + " [should be same as parsed lines not read]")

// Build the actual family "tree".
smry("\nBuilding ancestry from structured data ...")
let ancestry = Ancestry(dataForest, errors: errorsfile)
smry("Lines ignored: \(ancestry.unusedLineCount) [should be 0]")
let nPersons = ancestry.people.count
let nFamilies = ancestry.families.count
let nNotes = ancestry.notes.count
smry("Persons: \(nPersons)")
smry("Families: \(nFamilies)")
smry("Notes: \(nNotes)")
smry("\"Records (tree roots) built\" should be Persons + Families + Notes + 3.")
smry("    (3 is the number of non-data records: HEAD, SUBM and TRLR.)")
if nRoots == nPersons + nFamilies + nNotes + 3 {
    smry("... yes, \(nRoots) = "
         + "\(nPersons) + \(nFamilies) + \(nNotes) + 3")
} else {
    smry("... trouble!  \(nRoots) not= "
         + "\(nPersons) + \(nFamilies) + \(nNotes) + 3")
}

// For more information, set printUnreadLines: true in data.countUnread().
smry("Parsed lines not read: \(data.countUnread()) [should be 0]")
// For more information, set printUnreadLines: true in dataForest.countUnread().
smry("Tree nodes not read: \(dataForest.countUnread()) [should be 0]")

// Produce the report.
let reporter = Reporter(ancestry, infileName, showPersonIDs, sortReport,
    reportFile: reportfile, errors: errorsfile)
reporter.report()

// Summarize.
if !errorsfile.hasBeenUsed {
    errorsfile.writeln("No errors were reported during processing.\n")
}
else {
    errorsfile.writeln("\nEnd of error reports\n")
}
errorsfile.writeln("Summary of results:\n")
errorsfile.writeln(summary)

// Flush any output files with unwritten output.
try OutFile.finalizeAll()
