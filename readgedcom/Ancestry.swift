//
//  Ancestry.swift
//  readgedcom
//
//  Created by Jim Clarke on 2021-05-06.
//

// The people, notes and families extracted from a DataForest.


import Foundation
import StringUtilities
import TextFileUtilities


// A GedcomXREF is a GEDCOM "pointer": a string starting and ending with '@',
// containing between the @s a substring such as:
//   I0010 -- an individual
//   F0002 -- a family
//   NI009 -- a note about the individual I009
//   N0002 -- a note about the file as a whole, or a second note about I0002
// Of course, there may be other forms I haven't seen.

// We're not going to use GedcomXREFs directly, but that's what a NoteID is (see
// below), and making this explicit might help both understanding now and
// changes later.
typealias GedcomXREF = String

// A PersonID is a positive integer, unique to each Person. It is extracted
// from the input data, and is used as the key to "people", a dictionary.
//
// A FamilyID is similar, for a family.
//
// A NoteID identifies a note. It cannot be just an integer, because there are
// GEDCOM XREF:NOTEs of at least two forms: "@NI009@", to an individual's
// record, and "@N0002@", to a record of unspecified type, which might be the
// overall file header, or to an individual's record (where that individual
// already has an earlier note), or very likely to things I haven't seen yet.
// The NoteID string is the GEDCOM XREF without the '@' at each end.

typealias PersonID = Int
typealias FamilyID = Int
typealias NoteID = GedcomXREF


struct Event {
    var date: String?
    var place: String?
}

struct DateTime {
    var date: String?
    var time: String?
}

struct Note {
    var noteID: NoteID // a string, remember
    var belongsTo: PersonID?
    var contents = [String]() // one String per paragraph

    init(_ noteID: NoteID) {
        self.noteID = noteID
    }
}


class Header {
    // Information from the very first top-level record in the GEDCOM file. We
    // use only part of it here.
    
    var when: DateTime?
    var software: String?
    var softwareVersion: String?
    var embeddedFileName: String? // the file name in the GEDCOM file header
    var otherFileName: String? // for later use
        // -- maybe the file name from the command line?
    var gedcomVersion: String?
    var noteIDs = [NoteID]() // zero or more notes that are not about any person
    var notes: String? // to be set by a Reporter based on noteIDs
}

class Submitter {
    // Not used at present.
}


struct Name {
    // The GEDCOM standard specifies the parts listed. Apart from baseName,
    // all are optional in GEDCOM 5.5.1, but required in 5.5.5. As of Sept
    // 2020, we use at most the parts noted below -- some inserted automatically
    // by Gramps -- but eventually some version of some software will require
    // the rest, hopefully providing default values as needed.
    //
    // In addition, the standard allows an individual to have more than one
    // name. The first one listed is considered the preferred name.
    
    // GEDCOM field names are in parentheses below.
        
    var baseName: String // (not a GEDCOM field) must be present
    var givenName: String? // (GIVN) given name, part of the baseName
    var surName: String? // (SURN) family name, the part of the baseName
    // enclosed in "/.../" unless part is broken off for surnamePrefix. If SURN
    // is not supplied in the data, we initialize surName to "" when building
    // the Person's nameForSorting.
    //
    // Gramps extracts the givenName and the surName from the baseName, so both
    // are (almost?) always present.
    
    // Gramps note, which might as well go here:
    //
    // Gramps has some not necessarily standard (i.e., not in GEDCOM 5.5.5)
    // kinds of names, including:
    //
    // Chosen: non-standard, exported as "2 TYPE Chosen"
    // Call Name: non-standard, not exported; expected to be part of the Given
    //  Names
    // Nick Name: standard, exported as "2 NICK <value>"
    //
    // Here, we will use the Nick Name and report it as "known as". This will
    // work for people who are known by their middle name, even though it is not
    // strictly a nickname. We will use Chosen as a name type where it's
    // appropriate, with fingers crossed that it will survive the transition to
    // non-Gramps software.
    
    var prefix: String? // (NPFX) a name prefix such as "Dr", "Brigadier", etc.
    // The original file that started this whole thing used the TITL instead of
    // NAME.NPFX (the prefix), but apparently GEDCOM thinks titles are only for
    // the nobility. Gramps supports NPFX with a "Title" attribute to the name,
    // while using TITL for a separate attribute (not part of the name) that it
    // calls "Nobility Title". We show only one individual with a title, and
    // that is really a prefix.
    
    var nickName: String? // (NICK) nickname
    var surnamePrefix: String? // (SPFX) surname prefix, such as "de la", "von"
    var suffix: String? // (NSFX) suffix, such as "Jr."
    
    var type: String? // might be used to determine Name.kind (below), but
    // could also be some nonstandard string that Gramps uses, such as "Chosen"
    
    // Names can be of various kinds. We'll assume .birth unless told
    // otherwise.
    enum NameKind {case aka, birth, immigrant, maiden, married}
    var kind: NameKind
    
    init(baseName: String) {
        self.baseName = baseName
        kind = .birth
    }
}

class Person {
    var personID: PersonID
    var changeDate: DateTime?
    var names = [Name]() // The caller is responsible for ensuring that there is
    // at least one name. If there are more than one, the first one is to be
    // chosen if there is no explicit requirement for one or more others.
    var nameForSorting: String // used only inside the program, and must be set
    // var knownAs: String? // no longer used, since GEDCOM allows and expects
    // multiple names instead of allowing aliases under the ALIA tag.
    var sex: String?
    var title: String?
    var birth: Event?
    var death: Event?
    var burial: Event?
    var emigration: Event?
    
    // relationships to parents in various families
    var pedigrees = [FamilyID : (String?, String?)]() // father, mother
    
    // var notesExpected: [NoteID]() // zero or more identifiers of expected notes
    var noteIDs = [NoteID]() // notes about this person
    // Notes are level-0 entities in a GED file, with their own identifiers.
    // If they are notes about an individual, the first one has an identifier
    // of the form "NIppp" where ppp is the individual's personID. Later notes
    // about that individual, or notes about the file as a whole, have the form
    // "Niiii", where iiii is simply a note number.
    //
    // Notes about a person are linked to by subrecords of thepPerson's record,
    // like this:   1 NOTE @NI007@
    // The fact that the NI... form of noteID includes a personID seems of
    // merely sentimental interest: you can't count on it, because other notes
    // on the same Person will have to have noteIDs of the form N....
    //
    // Notes about the file as a whole are not linked from anywhere. As far as I
    // can tell, you just have to make a list of all the notes and remove the
    // ones that are linked from persons.
    //
    // Or those are my guesses from the Gramps-issued export files I've seen.
    
    // Family membership: familyC comes from the input's FAMC tag, and
    // describes one of the Person's birth families; familyS comes from the FAMS
    // tag, and describes one of the families in which the Person is a wife
    // or husband. The Person's children, listed in familyS, list that family
    // as a familyC of their own.
    var familyS: [FamilyID]? // list of indices of the family S ("started"?)
    var familyC: [FamilyID]? // list of indices of the family C ("child"?)
    
    init(_ personID: PersonID) {
        self.personID = personID
        nameForSorting = ""
    }
}

struct Child {
    var personID: PersonID
    var relationToFather: String?
    var relationToMother: String?
    
    init(_ personID: PersonID) {
        self.personID = personID
    }
}

// We need to be able to tell whether one Child is the same person as another.

extension Child: Equatable {
    static func == (one: Child, two: Child) -> Bool {
        return one.personID == two.personID
    }
}

struct Family {
    var familyID: FamilyID
    var changeDate: DateTime?
    var husband: PersonID?
    var wife: PersonID?
    var children: [Child] // could be an empty list, of course

    var marriage: Event? // A marriage is an event, and even if we know
    // there is a family, we may know or not know about the marriage.

    var beginStatus: String? // Currently we choose to ignore this, if it even
    // appears; it might usually be "Single", but "Partners" and "Private" have
    // been seen.

    // formerly used with the _FA1 tag, now happily vanished
    // var marriageFact: Event? // voodoo line to prevent reappearance
    
    var endStatus: String? // probably "Divorce" or "Death"
    var endEvent: Event?

    init(_ familyID: FamilyID) {
        self.familyID = familyID
        children = [Child]()
    }
}


// An Ancestry object is the thing we want to produce from a GEDCOM file.

class Ancestry {
    // in
    let dataForest: DataForest
    // let treeRoots: [RecordNode]
        
    // out: the parts of an Ancestry
    
    var header = Header()
    var submitter = Submitter()
    
    var people = [PersonID: Person]()
    var families = [FamilyID: Family]()
    var notes = [NoteID: Note]()
    var noteIDs = [NoteID]() // in the order they were read, please -- so we
    // can't use notes.keys
    
    // error reporting
    let errors: OutFile
    var unusedLineCount = 0

    
    init(_ dataForest: DataForest, errors: OutFile) {
        self.dataForest = dataForest
        // self.treeRoots = dataForest.roots // can't initialize in declaration
        self.errors = errors
        
        // We've now copied the raw data lines three times, I think. Probably
        // this is not a serious problem, because (1) the genealogy for one
        // family shouldn't have more than a few tens of thousands of lines,
        // and (2) Swift is supposed to be clever about not actually making new
        // copies of Strings if it can help it.
        //
        // But still.
        
        buildAncestry()
        checkAncestry()
    }
    
    
    func buildAncestry() {

        header = buildHeader(dataForest.roots[0])

        for r in 2 ... dataForest.roots.count - 2 {

            let treeRecord = dataForest.roots[r] // an object reference
            let dataLine = treeRecord.dataLine // also an object reference
            let lineNum = dataLine.lineNum // for labelling error messages

            guard let (kind, index) = atStrIntAt(dataLine.tag)
            else {
                errors.writeln(lineNum,
                    "line tag has bad pattern: \(dataLine.tag)")
                continue
            }
    
            switch kind {
            case "I":
                if dataLine.value != "INDI" {
                    errors.writeln(lineNum,
                                       "line with tag I but value not INDI"
                    )
                }
                if people[index] != nil {
                    errors.writeln(lineNum, "repeated personID \(index)")
                    continue
                }
                
                people[index] = buildPerson(treeRecord, personID: index)
                
                dataLine.hasBeenRead = true
 
            case "F":
                if dataLine.value != "FAM" {
                    errors.writeln(lineNum, "line with tag F but value not FAM")
                }
                if families[index] != nil {
                    errors.writeln(lineNum, "repeated familyID \(index)")
                    continue
                }
                
                families[index] = buildFamily(treeRecord, familyID: index)
                
                dataLine.hasBeenRead = true
  
            case "NI", "N":
                if !dataLine.value.starts(with: "NOTE") {
                    errors.writeln(lineNum,
                        "line with tag NI or N but value not starting with NOTE"
                    )
                }
                let noteID: NoteID = dataLine.tag
                if notes[noteID] != nil {
                    errors.writeln(lineNum, "repeated noteID \(noteID)")
                    continue
                }
                
                notes[noteID] = buildNote(treeRecord, noteID: noteID)
                noteIDs.append(noteID)
                
                dataLine.hasBeenRead = true
  
            default:
                errors.writeln(lineNum, "line with unknown tag \(kind)")
            }
        
        } // end of loop over records


        // Put the child-parent information where it belongs: in the Child
        // subrecords of Family records.
        //
        // We shouldn't have to do this, but the GEDCOM standard says to
        // export this information to the child's Person record, and we're
        // stuck dealing with that decision.

        // Let's assume that all the dictionary accesses are for valid keys.

        for f in families.keys {
            for c in 0 ..< families[f]!.children.count {
                let child = people[families[f]!.children[c].personID]
                var pediDad: String?
                var pediMom: String?
                (pediDad, pediMom) = child!.pedigrees[f]!
                families[f]!.children[c].relationToFather = pediDad
                families[f]!.children[c].relationToMother = pediMom
            }
        }


        // Straighten out the notes. Each Person has a list of NoteIDs for the
        // notes it wants to print. Presumably the notes in the list should be
        // printed in the order they are listed, so that's easy.
        //
        // But the header, which may also have notes, does not list them. We
        // figure out which notes belong to the header by noticing that no
        // person record wanted them, and we should print them in the order in
        // which they appear in the export file. That's the same as the order
        // in which they appear in the "notes" list.
        //
        // So: we already made a list of all the NoteIDs. Now we remove from the
        // list all the NoteIDs that are in the Person.noteIDs field for some
        // Person (that is, for at least one Person).

        // Scan all the persons and remove the noteIDs they want to print from
        // the list.
        for who in people.values {
            for nID in who.noteIDs {
                if let index = noteIDs.firstIndex(of: nID) {
                    noteIDs.remove(at: index)
                }
                // else{} We don't care. It's possible that some other person
                // also wanted to use this note, so it might already have been
                // removed.
            }
        }

        // Tell the header that it owns the remaining noteIDs.
        header.noteIDs = noteIDs
        
    } // end of buildAncestry


    // Return the number of lines in the input that were unused in constructing
    // this Ancestry -- apart from header, submitter and trailer lines.
    
    func checkAncestry() {
        // Have we looked at all the information provided by the genealogist?

        // Report on input records that were not used in the tree with the
        // given root, and return the number found.
        //
        // THESE ERROR REPORTS ARE CRUCIAL. They tell us whether we've missed
        // parts of the tree. And, fussily, we have other seemingly redundant
        // checks that might find the same problem ... or are they really
        // redundant?

        func reportUnusedRecords(root: RecordNode) -> Int {
            var count = 0
            if !root.dataLine.hasBeenRead {
                count += 1
                errors.writeln(root.dataLine.lineNum,
                    "line ignored: \(root.dataLine.asRead)")
            }
            
            for child in root.childNodes {
                count += reportUnusedRecords(root: child)
            }
            
            return count
        }

        unusedLineCount = 0
        for r in 2 ... dataForest.roots.count - 2 {
            unusedLineCount += reportUnusedRecords(root: dataForest.roots[r])
        }
    }


    // Assign value to toBeSet if it is nil. If it is not nil, do not change its
    // value, but report a problem to errors, referring to the line number
    // lineNum, the identifier associated with toBeSet, and the current value
    // of toBeSet.

    func checkedAssignString(toBeSet: inout String?,
                             value: String,
                             identifier: String,
                             lineNum i: Int
    )
    {
        if toBeSet != nil {
            errors.writeln(i, "attempt to overwrite \(identifier) \(toBeSet!)")
            return
        }
        toBeSet = value
    }


    // For each child node of parent, if the tag matches a tag in tags, extract
    // the value and return it as an element of the returned array. The
    // returned values are in the same order as the corresponding tags.
    //
    // If there is no value corresponding to a tag, nil is returned for that
    // tag. If a tag appears two or more times, the values after the first are
    // ignored, with an error message. All nodes that have matching tags are
    // marked as read, including even those that are ignored repeats.
    //
    // Records with tags that are not in the list of tags are ignored and are
    // not marked as read.
    //
    // This function checks only direct child nodes of parent -- not grandchild
    // nodes.

    func getFromChildrenByTags(parent: RecordNode, tags: [String]) -> [String?]
    {
        var result: [String?] = Array(repeating: nil, count: tags.count)
    
        for node in parent.childNodes {
            let tag = node.dataLine.tag
            if let which = tags.firstIndex(of: tag) {
                if result[which] != nil {
                    errors.writeln(node.dataLine.lineNum,
                        "attempt to overwrite \(tag) value \(result[which]!)")
                } else {
                    result[which] = node.dataLine.value
                }
                node.dataLine.hasBeenRead = true // whether we used it or not
            }
        }
    
        return result
    }


    // Return a DateTime from record -- a node tagged "DATE" containing a date
    // -- and its child node tagged "TIME". There may be other children, but
    // the TIME node must be the first child node. Both the DATE node and the
    // TIME node are marked as read, except that if record is not a DATE node,
    // then the TIME node is not read, even if it is present.
    //
    // If problems are encountered, an error is reported, and nil is returned.

    func getDateTime(record: RecordNode) -> DateTime?
    {
        guard record.dataLine.tag == "DATE" else {
            errors.writeln(record.dataLine.lineNum,
                "tag DATE not found when expected")
            return nil
        }
        record.dataLine.hasBeenRead = true
    
        guard record.childNodes.count > 0
                && record.childNodes[0].dataLine.tag == "TIME" else {
            errors.writeln(record.dataLine.lineNum,
                "tag TIME not found (in child record) when expected")
            return nil
        }
        record.childNodes[0].dataLine.hasBeenRead = true

        return DateTime(date: record.dataLine.value,
            time: record.childNodes[0].dataLine.value)
    }


    // Extract bibliographic information -- not part of the records about people
    // and families. Actual genealogists might not want all this stuff.

    func buildHeader(_ record: RecordNode) -> Header {
        var header = Header()

        for subtree in record.childNodes {
            let line = subtree.dataLine
            let lineNum = line.lineNum // used frequently in error messages
            
            switch line.tag {
            case "DATE":
                header.when = getDateTime(record: subtree)
            case "SOUR":
                let values = getFromChildrenByTags(parent: subtree,
                                                   tags: ["NAME", "VERS"]
                )
                if values[0] != nil {
                    checkedAssignString(toBeSet: &header.software,
                                        value: values[0]!,
                                        identifier: "software",
                                        lineNum: lineNum
                    )
                }
                if values[1] != nil {
                    checkedAssignString(toBeSet: &header.softwareVersion,
                                        value: values[1]!,
                                        identifier: "software version",
                                        lineNum: lineNum
                    )
                }
            case "GEDC":
                let values = getFromChildrenByTags(parent: subtree, tags: ["VERS"])
                if values[0] != nil {
                    checkedAssignString(toBeSet: &header.gedcomVersion,
                                        value: values[0]!,
                                        identifier: "GEDCOM version",
                                        lineNum: lineNum
                    )
                }
            case "FILE":
                if line.value == "" {
                    errors.writeln(lineNum, "empty file name in header")
                }
                checkedAssignString(toBeSet: &header.embeddedFileName,
                                    value: line.value,
                                    identifier: "file name in header",
                                    lineNum: lineNum)
            default:
                break
            }

            // There are lines in the header we don't feel obliged to handle.
            // Consequently, we don't set child.dataLine.hasBeenRead, and
            // the default case doesn't say:
            // errors.writeln(lineNum, "line ignored: \(child.dataLine.asRead)")

 
        } // end of the loop on child treenodes

        return header

    } // end of buildHeader


    // Return a Person constructed from the record and the personID.
    //
    // The personID is available from the record itself, but it is extracted and
    // checked before this function is called.

    func buildPerson(_ record: RecordNode, personID: PersonID) -> Person {
        var who = Person(personID)
    
        for subtree in record.childNodes {
            let line = subtree.dataLine
            let lineNum = line.lineNum // used frequently in error messages

            switch line.tag {
            case "CHAN":
                if line.value != "" {
                    errors.writeln(lineNum, "non-empty value in CHAN line")
                }

                // Read the child DATE node and grandchild TIME node.
                if subtree.childNodes.count < 1 {
                    errors.writeln(subtree.dataLine.lineNum,
                        "CHAN node doesn't start with a DATE child")
                }
                else {
                    who.changeDate = getDateTime(record: subtree.childNodes[0])
                }
                subtree.dataLine.hasBeenRead = true
        
            case "NAME":
                // var name = Name(baseName: line.value)
                // let trimmedName = line.value.trimmingCharacters(in: .whitespaces)
                let trimmedName = trimWhitespace(line.value)
                var name = Name(baseName: trimmedName)
                // if line.value == "" {
                if trimmedName == "" {
                    errors.writeln(lineNum, "empty name in NAME record")
                }

                // Set the dangling extras for a name. This is fairly ugly.
                let values = getFromChildrenByTags(parent: subtree,
                                                   tags:
                    ["TYPE", "GIVN", "SURN", "NPFX", "NICK", "SPFX", "NSFX"])
                (name.type, name.givenName, name.surName, name.prefix, name.nickName,
                    name.surnamePrefix, name.suffix)
                    =
                    (values[0], values[1], values[2], values[3], values[4],
                        values[5], values[6])

                switch name.type {
                case nil:
                    // the usual case, I think
                    break;

                case "aka":
                    name.kind = .aka
                case "birth":
                    name.kind = .birth
                case "immigrant":
                    name.kind = .immigrant
                case "maiden":
                    name.kind = .maiden
                case "married":
                    name.kind = .married
                
                default:
                    break;
                }
           
                who.names.append(name)
                subtree.dataLine.hasBeenRead = true
        
            // The ALIA record is no longer defined in GEDCOM.
            // else if line.tag == "ALIA" {
        
            case "SEX":
                checkedAssignString(toBeSet: &who.sex, value: line.value,
                    identifier: "sex", lineNum: lineNum)
                subtree.dataLine.hasBeenRead = true
        
            case "TITL":
                // Needed only if we get nobility into the family.
                checkedAssignString(toBeSet: &who.title, value: line.value,
                    identifier: "title", lineNum: lineNum)
                subtree.dataLine.hasBeenRead = true
        
            case "BIRT", "DEAT", "BURI", "EMIG":
                // events that need a date and a place
                if line.value != "" {
                    errors.writeln(lineNum,
                        "expected empty value in line: \(line)")
                }
                var overwriteError = false
                switch line.tag {
                case "BIRT":
                    overwriteError = who.birth != nil
                case "DEAT":
                    overwriteError = who.death != nil
                case "BURI":
                    overwriteError = who.burial != nil
                case "EMIG":
                    overwriteError = who.emigration != nil
                default:
                    errors.writeln(lineNum,
                        "supposedly impossible tag \(line.tag) in line: \(line)")
                }
                if overwriteError {
                    // I'd like to include the value that would be overwritten,
                    // but that would require excessive gymnastics.
                    errors.writeln(lineNum,
                        "line attempts to overwrite value: \(line)")
                } else {
                    let values = getFromChildrenByTags(parent: subtree,
                                                       tags: ["DATE", "PLAC"])
                    var newEvent: Event? = nil
                    if values[0] != nil || values[1] != nil {
                        newEvent = Event(date: values[0], place: values[1])
                    }
                    switch line.tag {
                    case "BIRT":
                        who.birth = newEvent
                    case "DEAT":
                        who.death = newEvent
                    case "BURI":
                        who.burial = newEvent
                    case "EMIG":
                        who.emigration = newEvent
                    default:
                        break
                    }
                }
                subtree.dataLine.hasBeenRead = true
                
            case "NOTE":
                // if let (valueKind, valueIndex) = atStrIntAt(line.value) {
                if let (valueKind, _) = atStrIntAt(line.value) {
                    if valueKind != "NI" && valueKind != "N" {
                        errors.writeln(lineNum, "bad note ID: \(line.value)")
                    // } else if who.noteExpected != nil {
                    //     errors.writeln(lineNum, "second note expected for same person")
                    } else {
                        who.noteIDs.append(line.value)
                    }
                } else {
                    errors.writeln(lineNum, "bad note ID: \(line.value)")
                }
                subtree.dataLine.hasBeenRead = true

            case "FAMS", "FAMC":
                if let (valueKind, valueIndex) = atStrIntAt(line.value) {
                    if valueKind != "F" {
                        errors.writeln(lineNum, "bad family ID: \(line.value)")
                    } else {
                        if line.tag == "FAMS" {
                            if who.familyS == nil {
                                who.familyS = [FamilyID]()
                            }
                            who.familyS!.append(valueIndex)
                        } else {
                            assert(line.tag == "FAMC")
                            if who.familyC == nil {
                                who.familyC = [FamilyID]()
                            }
                            who.familyC!.append(valueIndex)

                            // In GEDCOM 5.5.5, the pedigree (tag "PEDI") is
                            // part of the child's FAMC record, and Gramps does
                            // this. Gramps also allows alternatives to PEDI:
                            // _MREL and _FREL for the relationships to the
                            // parents separately.
                            //
                            // This is an odd place to put this information,
                            // which is really part of the family relationship,
                            // not the child alone. But here we are.
                            let values = getFromChildrenByTags(parent: subtree,
                                tags: ["PEDI", "_FREL", "_MREL"])
                            // There can be a PEDI for both relationships, or an
                            // _FREL and/or an _MREL, but not both a PEDI and
                            // some of the other two.
                            if values[0] != nil {
                                if values[1] != nil || values[2] != nil {
                                    errors.writeln(lineNum,
                                "too much child-parent relationship information")
                                }
                                who.pedigrees[valueIndex] = (values[0], values[0])
                            }
                            else {
                                who.pedigrees[valueIndex] = (values[1], values[2])
                                // printerr("pedigrees: \(values[1] ?? "nil") \(values[2] ?? "nil")")
                            }
                        }
                    }
                } else {
                    errors.writeln(lineNum, "bad family ID: \(line.value)")
                }
                subtree.dataLine.hasBeenRead = true
                            
            default:
                errors.writeln(lineNum, "line ignored: \(subtree.dataLine.asRead)")
            }
            
        } // end of the loop on child treenodes
    
        return who

    } // end of buildPerson


    // Return a Family constructed from the record and the familyID.
    //
    // The familyID is available from the record itself, but it is extracted and
    // checked before this function is called.

    func buildFamily(_ record: RecordNode, familyID: FamilyID) -> Family {
        var family = Family(familyID)

        for subtree in record.childNodes {
            let line = subtree.dataLine
            let lineNum = line.lineNum // used frequently in error messages
            
            switch line.tag {
            case "CHAN":
                if line.value != "" {
                    errors.writeln(lineNum, "non-empty value in CHAN line")
                }
                
                // Read the child DATE node and grandchild TIME node.
                if subtree.childNodes.count < 1 {
                    errors.writeln(subtree.dataLine.lineNum,
                                   "CHAN node doesn't start with a DATE child")
                }
                else {
                    family.changeDate = getDateTime(record: subtree.childNodes[0])
                }
                subtree.dataLine.hasBeenRead = true
 
            case "HUSB", "WIFE":
                if let (valueKind, valueIndex) = atStrIntAt(line.value) {
                    if valueKind != "I" {
                        errors.writeln(lineNum,
                                       "bad husband/wife personID: \(line.value)")
                    } else {
                        if line.tag == "HUSB" {
                            if family.husband != nil {
                                errors.writeln(lineNum,
                                               "second personID for husband")
                            }
                            family.husband = valueIndex
                        } else {
                            if family.wife != nil {
                                errors.writeln(lineNum,
                                               "second personID for wife")
                            }
                            family.wife = valueIndex
                        }
                    }
                } else {
                    errors.writeln(lineNum,
                                   "bad husband/wife personID: \(line.value)")
                }
                subtree.dataLine.hasBeenRead = true
  
            case "MARR":
                if line.value != "" {
                    errors.writeln(lineNum, "MARR line with non-empty value")
                }
                let values = getFromChildrenByTags(parent: subtree,
                                                   tags: ["DATE", "PLAC"])
                var newEvent: Event? = nil
                if values[0] != nil || values[1] != nil {
                    newEvent = Event(date: values[0], place: values[1])
                }
                
                if newEvent != nil {
                    if family.marriage != nil {
                        errors.writeln(lineNum,
                                       "attempt to overwrite existing marriage event")
                    } else {
                        family.marriage = newEvent
                    }
                }
                
                subtree.dataLine.hasBeenRead = true
 
            case "DIV":
                if line.value != "" && line.value != "Y" {
                    errors.writeln(lineNum, "DIVorce line with unknown value")
                }
                
                family.endStatus = "Divorce"
                
                if line.value != "Y" {
                    // If "Y", all we know is that there was a divorce.
                }
                let values = getFromChildrenByTags(parent: subtree,
                                                   tags: ["DATE", "PLAC"])
                var newEvent: Event? = nil
                if values[0] != nil || values[1] != nil {
                    newEvent = Event(date: values[0], place: values[1])
                }
                
                if newEvent != nil {
                    if family.endEvent != nil {
                        errors.writeln(lineNum,
                                       "attempt to overwrite existing end event of marriage")
                    } else {
                        family.endEvent = newEvent
                    }
                }
                
                subtree.dataLine.hasBeenRead = true
 
            case "EVEN":
                if subtree.childNodes.count < 1 {
                    errors.writeln(lineNum,
                                   "EVEN record does not have a TYPE record")
                    // Don't even label the node as read
                    continue
                }
                
                let typeLine = subtree.childNodes[0].dataLine
                switch typeLine.value {
                
                case "Death":
                    // At least one spouse died. There may be a date and a
                    // place, giving a family.endEvent, but we ignore the
                    // line.value, because it probably says "there was a death".
                    family.endStatus = "Death"
                    let values = getFromChildrenByTags(parent: subtree,
                                                       tags: ["DATE", "PLAC"])
                    if values[0] != nil || values[1] != nil {
                        if family.endEvent != nil {
                            errors.writeln(lineNum,
                                           "attempt to overwrite existing end-of-marriage event")
                        } else {
                            family.endEvent
                                = Event(date: values[0], place: values[1])
                        }
                    }
                    subtree.childNodes[0].dataLine.hasBeenRead = true
                    
                // case "_FA1":
                // Family Tree Maker used this tag to record "facts" in the
                // old .GED files, in just two places, both related to
                // information about marriages. Gramps copied the tag in
                // those two places.
                //
                // Both instances of _FA1 have been
                // replaced by more appropriate directly marriage-related
                // tags. I hope _FA1 never reappears, but if it does, how
                // it is handled will depend on what information it holds.
                // Meanwhile, it's gone!
                
                case "_MSTAT":
                    // We hope not to be using this case, but here it is.
                    
                    // There are no further child nodes. We simply store
                    // line.value as beginStatus.
                    family.beginStatus = line.value
                    subtree.childNodes[0].dataLine.hasBeenRead = true
                    
                case "_MEND":
                    // We hope not to be using this case, but here it is.
                    
                    // We store line.value as endStatus. There may be DATE and
                    // PLAC values that locate the family-ending event.
                    family.endStatus = line.value
                    let values = getFromChildrenByTags(parent: subtree,
                                                       tags: ["DATE", "PLAC"])
                    if values[0] != nil || values[1] != nil {
                        if family.endEvent != nil {
                            errors.writeln(lineNum,
                                           "attempt to overwrite existing end-of-marriage event")
                        } else {
                            family.endEvent
                                = Event(date: values[0], place: values[1])
                        }
                    }
                    subtree.childNodes[0].dataLine.hasBeenRead = true
                    
                default:
                    errors.writeln(lineNum, "bad family event \(typeLine.value)")
                    // Don't label any nodes as read.
                    continue
                }
                
                subtree.dataLine.hasBeenRead = true
  
            case "CHIL":
                if let (valueKind, valueIndex) = atStrIntAt(line.value) {
                    if valueKind != "I" {
                        errors.writeln(lineNum,
                                       "bad child personID: \(line.value)")
                    } else {
                        let child = Child(valueIndex)
                        
                        // In GEDCOM 5.5.5, only the child's personID is given.
                        // We're going to add more information later -- such as
                        // the child's relation to its father and/or mother --
                        // but we can't get it while reading the family record.
                        // let linesUsed = buildChild(childToBuild: &child,
                        //     firstLine: record.lines[i + 1],
                        //     secondLine: record.lines[i + 2],
                        //     baseLineNumber: lineNum,
                        //     baseLevel: line.level,
                        //     errorsFile: &errorsfile
                        //     )
                        if family.children.first(where:
                                                    {$0.personID == child.personID})
                            != nil {
                            errors.writeln(lineNum, "duplicate child personID")
                        } else {
                            family.children.append(child)
                        }
                    }
                } else {
                    errors.writeln(lineNum, "bad child personID: \(line.value)")
                }
                subtree.dataLine.hasBeenRead = true

            default:
                errors.writeln(lineNum, "line ignored: \(subtree.dataLine.asRead)")
            }
            
        } // end of the loop on child treenodes
    
        return family
        
    } // end of buildFamily


    // Return a note -- that is, an array of Strings, each String a paragraph --
    // constructed from the record. The pointer in the first line of the record
    // is not used here; the caller should extract it to decide where to put the
    // note.

    func buildNote(_ record: RecordNode, noteID: NoteID) -> Note {
        var note = Note(noteID)
    
        let dataLine = record.dataLine
    
        var noteLine = ""

        // The note may start in the value segment of the first line.
        if dataLine.value.starts(with: "NOTE ") {
            let lineZero = dataLine.value
            let range = lineZero.index(lineZero.startIndex, offsetBy: 5)
                ..< lineZero.endIndex
            noteLine += lineZero[range]
        }

        for subtree in record.childNodes {
            let lineNum = subtree.dataLine.lineNum
            if subtree.childNodes.count != 0 {
                errors.writeln(lineNum, "bad line level in NOTE")
                continue
            }

            let line = subtree.dataLine.value // named variable just for clarity

            switch subtree.dataLine.tag {
            case "CONT":
                note.contents.append(noteLine)
                noteLine = ""
                fallthrough

            case "CONC":
                noteLine += line
                
            default:
                errors.writeln(lineNum, "bad line tag in NOTE")
            }
        
            subtree.dataLine.hasBeenRead = true
        }
    
        if noteLine != "" {
            note.contents.append(noteLine)
        }
    
        return note
    
    } // end of buildNote


} // end of Ancestry class definition


// Return the two variable parts of a string of the form @AAA999@ -- that is,
// an "at" sign, some upper-case ASCII letters, some digits, and then a final
// "at" sign. No part may be empty, and nothing besides the parts listed may be
// present.
//
// The digits part is returned as an Int, which may be 0 but obviously cannot
// be negative.
//
// If the string matching fails, nil is returned.

func atStrIntAt(_ inStr: String) -> (String, Int)? {

    // Default (error-signalling) values in case of trouble.
    let failResult: (String, Int)? = nil
    
    let pat = "^@([A-Z]+)([0-9]+)@$"
    
    let matches = applyRegex(regex: pat, target: inStr)

    if matches.count != 1 {
        return failResult
    }
    
    let matchStrings = matches[0]
    if matchStrings.count != 3 { // overall match, and the two parts
        return failResult
    }

    // Convert the second part to an integer.
    guard let secondInt = Int(matchStrings[2]) else {
        return failResult
    }
    // if secondInt <= 0 {
    //     return failResult
    // }
    
    return (matchStrings[1], secondInt)
}


