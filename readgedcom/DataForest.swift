//
//  DataForest.swift
//  readgedcom
//
//  Created by Jim Clarke on 2021-05-05.
//

// A forest (a bunch of trees) containing the GEDCOM records in a ParsedData.


import Foundation
import TextFileUtilities


// Every record (using "record" in the GEDCOM sense: "a sequence of tagged,
// variable-length lines, arranged in a hierarchy") in the list of DataLines is
// copied into a tree of RecordNodes. Each DataLine is the content of a
// RecordNode, and the "level" attribute of a DataLine corresponds (by
// construction) to the level in the tree of its containing RecordNode. Plus
// one.
//
// Every top-level record becomes the root of a separate tree, and the trees
// collectively are a forest, with the forest's root nodes stored in the list
// "topLevelRecords".
//
// (To have a single tree instead of a forest, we could make a dummy data line,
// with level -1, to use in the root of the tree, but we'd have to put the dummy
// line into the "data" list, and I don't want to mess with it like that.)


class RecordNode {
    var dataLine: DataLine // the field hasBeenRead needs to be changeable
    var childNodes = [RecordNode]() // shouldn't call this "children", since
    // that is a genealogical term too, and the genealogists got here first
    
    init(dataLine: DataLine) {
        self.dataLine = dataLine
    }
}

class DataForest {
    // in
    let parsedLines: [DataLine]
    
    // out
    
    // The root nodes in this DataForest. Each non-root nodes is linked to its
    // parent by inclusion in the parent's childNodes property.
    fileprivate(set) var rootNodes = [RecordNode]()
    
    // error reporting
    let errors: OutFile
    
    // properties
    var rootCount: Int { rootNodes.count }
    
    init(data: ParsedData, errors: OutFile) {
        self.parsedLines = data.parsedLines
        self.errors = errors
        
        buildForest()
        checkForest()
    }

    
    // Build this entire forest, returning the list of top-level records that
    // functions as a sort of root node (though there is no single root node:
    // this is a forest).

    func buildForest() {
        var lineNum = 0
        while lineNum < parsedLines.count {
            var newNode: RecordNode
            (newNode, lineNum) = makeNode(lineNum)
            rootNodes.append(newNode)
        }
    }


    // Construct a RecordNode from the data in parsedLines[lineNum], and also
    // construct all its child RecordNodes, and link them to the new RecordNode
    // as roots of its subtrees..
    //
    // Return the newly constructed node and also the line number of the next
    // data line to be stored in a RecordNode.

    func makeNode(_ lineNum: Int) -> (RecordNode, Int) {
        let node = RecordNode(dataLine: parsedLines[lineNum])
    
        var newLineNum = lineNum + 1
        while newLineNum < parsedLines.count
                && parsedLines[newLineNum].level == node.dataLine.level + 1 {
            var newNode: RecordNode
            (newNode, newLineNum) = makeNode(newLineNum)
            node.childNodes.append(newNode)
        }
    
        return (node, newLineNum)
    }


    // Check this forest. At least some of these checks are implicit in later
    // work, but it never hurts to check what you can when you can.
    //
    // Trouble is indicated by output to errors, not by a return value or a
    // thrown Error.

    func checkForest() {
    
        // Check the header, submitter and trailer records, which are
        // special in GEDCOM.
    
        // header
        let headerLine = rootNodes[0].dataLine
        let headerLineOK = headerLine.level == 0
            && headerLine.tag == "HEAD"
            && headerLine.value == ""
        if !headerLineOK {
            errors.writeln("bad header record first line")
        }
    
        // submitter
        let submitterLine = rootNodes[1].dataLine
        let submitterLineOK = submitterLine.level == 0
            && submitterLine.tag == "@SUBM@"
            && submitterLine.value == "SUBM"
        if !submitterLineOK {
            errors.writeln("bad submitter record first line")
        }
    
        // trailer
        let trailerNode = rootNodes[rootNodes.count - 1]
        let trailer = trailerNode.dataLine
        let trailerOK = trailer.level == 0
            && trailer.tag == "TRLR"
            && trailer.value == ""
            && trailerNode.childNodes.count == 0
        if !trailerOK {
            errors.writeln("bad trailer record")
        }
    }
}
