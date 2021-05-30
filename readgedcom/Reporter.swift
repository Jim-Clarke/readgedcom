//
//  Reporter.swift
//  readgedcom
//
//  Created by Jim Clarke on 2021-05-13.
//

// Producing a text file with the information from an Ancestry.


import Foundation
//import StringUtilities
import TextFileUtilities


// Output helpers
fileprivate let LINE_LENGTH = 75
fileprivate let UNDERLINE = String(repeating: "-", count: LINE_LENGTH)
fileprivate let NL = "\n"


// Currently ReportingErrors are only thrown while reporting information about
// Families.
enum ReportingError: Error {
    case report(_ who: PersonID, _ msg: String)
}


extension Header : CustomStringConvertible {
    var description: String {
        var result = ""
        
        result += UNDERLINE + NL
        // I'm not sure we want to emphasize the original file name.
        // if let embeddedFileName = embeddedFileName {
        //     result += "Reporting on file \"\(embeddedFileName)\"" + NL
        //     result += UNDERLINE + NL
        // }
        if let otherFileName = otherFileName {
            result += "Reporting on file \"\(otherFileName)\"" + NL
            result += UNDERLINE + NL
        }

        if let when = when {
            result += "Export date:"
            if let date = when.date {
                result += " " + date
            }
            if let time = when.time {
                result += " " + time
            }
            result += NL
        }
        
        if let software = software {
            result += "Export file produced by " + software
            if let softwareVersion = softwareVersion {
                result += " version " + softwareVersion
            }
            result += NL
        }
        
        if let gedcomVersion = gedcomVersion {
            result += "GEDCOM version " + gedcomVersion + NL
        }
        
        if noteIDs.count > 0 {
            result += UNDERLINE + NL
            result += "Notes on file, possibly automatically generated:" + NL
            result += UNDERLINE + NL
            if let notes = notes {
                result += notes
            }
            result += UNDERLINE + NL
            result += "END OF INFORMATION ABOUT THE FILE" + NL
        }
        
        result += UNDERLINE + NL + NL + NL
        
        return result
    }
}

func familyIDString(_ familyID: FamilyID) -> String {
    // if SHOW_FAMILYIDS {
        return "[\(familyID)]"
    // } else {
    //     return "[ff]"
    // }
}

extension Event : CustomStringConvertible {
    var description: String {
        var result = ""
        // if date != nil || place != nil {
        //     result += "date: " + (date ?? "")
        //     result += "  place: " + (place ?? "")
        // }
        
        if date != nil {
            result += "date: " + date!
            if place != nil {
                result += "  "
            }
        }
        if place != nil {
            result += "place: " + place!
        }
        return result
    }
}
        
extension Person : CustomStringConvertible {
    var description: String {
        var result = ""
        
        // We are ignoring the changeDate.
        
        result += UNDERLINE + NL
        // if let name = name {
        //     result += name + NL
        if names.count > 0 {
            result += names[0].baseName
            if let type = names[0].type {
                result += "  (\(type) name)"
            }
            result += NL
        }
        else {
            result += "(no name)" + NL
        }
        result += UNDERLINE + NL
        
        result += "[\(personID)]: "
        
        // The treatment of sex is a kluge, very possibly Gramps-specific.
        // The GEDCOM standard allows MFXUN (male/female/intersex/unknown/not
        // recorded), but Gramps only allows MF. "Unknown" is selectable but
        // results in omission of the sex in an exported .ged file.
        //
        // We're going to assume -- for Gramps use only? -- that an omitted sex
        // should be X. If you're a U or an N, tell us your sex, please.
        if let sex = sex {
            if sex == "M" {
                result += "male"
            } else if sex == "F" {
                result += "female"
            } else {
                // result += "unknown sex"
                result += sex
            }
        }
        else { // no sex supplied;
            result += "X"
        }
        
        // further information from the primary name
        if let prefix = names[0].prefix {
            // This is a regular title such as "Dr."
            result += "  title: " + prefix
        }
        if let title = title {
            // GEDCOM and Gramps consider this as a "nobility title".
            result += "  title: " + title
        }
        result += NL
        
        if let nickName = names[0].nickName {
            // This may not be strictly a "nickname" as in the usual usage.
            result += "    known as: " + nickName + NL
        }
        
        // Treat other names as "known as". There's a name kind .aka, but we
        // don't need it for the current export file.
        for n in 1 ..< names.count {
            var nameLabel: String
            if let type = names[n].type {
                nameLabel = type + " name: "
            }
            else {
                nameLabel = "Other name: "
            }
            result += nameLabel + names[n].baseName + NL
            
            if let nickName = names[n].nickName {
                result += "    known as: " + nickName + NL
            }
        }
        
        if let birth = birth {
            if birth.description != "" {
                result += "birth:    " + birth.description + NL
            }
        }
        if let death = death {
            if death.description != "" {
                result += "death:    " + death.description + NL
            }
        }
        if let burial = burial {
            if burial.description != "" {
                result += "burial:   " + burial.description + NL
            }
        }
        if let emigration = emigration {
            if emigration.description != "" {
                result += "emigration:   " + emigration.description + NL
            }
        }
                
        // End of this person's description
        // result += NL
        
        return result
    }
}


// If you want to report on people separately from families, the following two
// commented-out sections might help. But be careful: they may rely on
// definitions that are no longer valid.

//// Return a description of a Person's family relations, without resolving
//// details.
//
//func personsFamilyConnections(_ person: Person) -> String {
//    var result = ""
//
//    if let familyC = person.familyC {
//        result += "Family C:"
//        for f in familyC {
//            result += "  " + familyIDString(f)
//        }
//        result += NL
//    }
//
//    if let familyS = person.familyS {
//        result += "Family S:"
//        for f in familyS {
//            result += "  " + familyIDString(f)
//        }
//        result += NL
//    }
//
//    return result
//}

//extension Family : CustomStringConvertible {
//    var description: String {
//        var result = ""
//
//        // We are ignoring the changeDate.
//
//        result += UNDERLINE + NL
//        // result += "Family [\(familyID)]" + NL
//        result += "Family \(familyIDString(familyID))" + NL
//        result += UNDERLINE + NL
//
//        if let husband = husband {
//            result += "husband: \(personsNameString(husband))" + NL
//        }
//
//        if let wife = wife {
//            result += "wife: \(personsNameString(wife))" + NL
//        }
//
//        var counter = 1
//        for c in children {
//            result += "child \(counter): \(personsNameString(c.personID))" + NL
//            counter += 1
//        }
//
//        if let marriage = marriage {
//            result += "marriage:   " + marriage.description + NL
//        }
//
//        if let begin = beginStatus {
//            result += "marriage beginning status:   " + begin.description + NL
//        }
//
//        if let end = endStatus {
//            result += "marriage ending status:   " + end.description + NL
//        }
//
//        if let endEvent = endEvent {
//            result += "marriage end: " + endEvent.description + NL
//        }
//
//        // End of this family's description
//        result += NL
//
//        return result
//    }
//}




class Reporter {
    
    let ancestry: Ancestry
    let showPersonIDs: Bool
    let sortReport: Bool
    let reportFile: OutFile
    let errors: OutFile
    
    init(_ ancestry: Ancestry,
         _ infileName: String,
         _ showPersonIDs: Bool,
         _ sortReport: Bool,
         reportFile: OutFile,
         errors: OutFile)
    {
        self.ancestry = ancestry
        self.ancestry.header.otherFileName = infileName
        self.showPersonIDs = showPersonIDs
        self.sortReport = sortReport
        self.reportFile = reportFile
        self.errors = errors
        
        // header needs a little more help
        ancestry.header.notes = formattedNoteList(ancestry.header.noteIDs)
    
    }

    func report() {
        
        // Sort the people -- either by personID (the default) or by name if
        // sortReport is true.
        
        let people = ancestry.people // var: because need to be able to change
        // nameForSorting ... nope, can't. We're copying structs here.
        
        // The list of people to be printed: has to be constructed separately
        // for the unsorted and sorted cases.
        var sortedPeople = [Person]()
        
        if !sortReport {
            // Sort by personID -- the key to the "people" dictionary.
            for p in people.keys.sorted() {
                guard let who = people[p]
                else {
                    errors.writeln("bad key \(p) in people.keys")
                    continue
                }
                sortedPeople.append(who)
            }
        }
        else {
            // Sort by name: copy the unsorted list of people to sortedPeople,
            // give each list item its sort key, and then sort the list.
            
            // Build the list.
            for who in people.values {
                sortedPeople.append(who)
            }

            // Make the sort keys.
            for who in sortedPeople {
            // for w in 0 ..< sortedPeople.count {
            //     let who = sortedPeople[w]
            //     // Careful! Person is a struct, not a class -- changes to "who"
            //     // will vanish when we leave this loop.
                var sortingName: String
                if who.names.count > 0 {
                    // Probably surName already has a value, but let's be
                    // careful.
                    sortingName = who.names[0].surName ?? ""
                    sortingName += who.names[0].baseName
                    // The surName will be repeated, because it's part of the
                    // baseName, but that won't change the sorting; and if
                    // surnamePrefix is supplied, then surName does not include
                    // it, so sorting will be correct.
                } else {
                    sortingName = "/no name/"
                }
                who.nameForSorting = sortingName
                // sortedPeople[w].nameForSorting = sortingName
            }
            
            // Sort the list.
            sortedPeople.sort(
                by: {($0.nameForSorting < $1.nameForSorting)
                    || (($0.nameForSorting == $1.nameForSorting)
                            && ($0.personID < $1.personID))
                })
        }


        // Sorted. Write!
        
        reportFile.write("\(ancestry.header)")

        for who in sortedPeople {
            
            // Build up the major output file carefully, so as to get newlines
            // only where we really want them.
            
            reportFile.write("\(who)")
            do {
                try reportFile.write(personsFamilyDetails(who))
            } catch ReportingError.report(let person, let msg) {
                errors.writeln(
                    personsNameString(person, showPersonIDs) + " " + msg)
            } catch {
                errors.writeln("unknown error: \(error)")
            }
            reportFile.write(NL)
            reportFile.write(personNotes(who))
            reportFile.write(NL)
        }
    }

    
    // Return a description of the details of a Person's familyC relations --
    // that is, the families in which the person was a child.

    func personsFamilyCDetails(_ person: Person, _ familyC: [FamilyID])
            throws -> String {
        var result = ""
        
        // Are there any families here?
        if familyC.count == 0 {
            throw ReportingError.report(person.personID, "empty familyC")
        }
        
        // let multiple = familyC.count > 1
        
        // Should we say "Parent" or "Parents"?
        var pluralParents = familyC.count > 1
        // OK, but are there two parents in the (sole) family?
        if !pluralParents {
            guard let soleFamily = ancestry.families[familyC[0]]
            else {
                throw ReportingError.report(person.personID, "bad key in familyC")
            }
            if soleFamily.husband != nil && soleFamily.wife != nil {
                pluralParents = true
            }
        }
        let parentLabel = pluralParents ? "Parents" : "Parent"
        
        result += parentLabel + ":" + NL
        var parentList = [PersonID]() // to avoid listing a parent twice
        var whichFamily = 0
        for f in familyC {
            whichFamily += 1
            guard let family = ancestry.families[f]
            else {
                throw ReportingError.report(person.personID, "bad key in familyC")
            }
            
            let me = family.children.first() {$0.personID == person.personID}
            if me == nil {
                throw ReportingError.report(person.personID, "not listed as child")
            }
            
            if let husband = family.husband {
                if !parentList.contains(husband) {
                    parentList.append(husband)
                    result += "    " + personsNameString(husband, showPersonIDs)
                    if let frel = me!.relationToFather {
                        // We're counting on the user to use the same
                        // relationship modifier in all mentions of a parent.
                        // This is irrelevant in our particular data.
                        if frel != "" && frel != "birth" {
                            result += " (\(frel)-parent)"
                        }
                    }
                    result += NL
                }
            }
            if let wife = family.wife {
                if !parentList.contains(wife) {
                    parentList.append(wife)
                    result += "    " + personsNameString(wife, showPersonIDs)
                    if let mrel = me!.relationToMother {
                        // We're counting on the user to use the same
                        // relationship modifier in all mentions of a parent.
                        // This is irrelevant in our particular data.
                        if mrel != "" && mrel != "birth" {
                            result += " (\(mrel)-parent)"
                        }
                    }
                }
                result += NL
            }
        }
        // result += NL
        
        return result
    }


    // Return a description of the details of a Person's familyS relations --
    // that is, the families in which the person was a parent.

    func personsFamilySDetails(_ person: Person, _ familyS: [FamilyID])
            throws -> String {
        var result = ""
        
        // Are there any families here?
        if familyS.count == 0 {
            throw ReportingError.report(person.personID, "empty familyS")
        }

        var whichFamily = 0
        var childList = [Child]() // to avoid listing a child twice
        // -- including with a second marriage that carries children over from
        // the first marriage
        for f in familyS {
            whichFamily += 1
            guard let family = ancestry.families[f]
            else {
                throw ReportingError.report(person.personID, "bad key in familyS")
            }

            // Am I the husband or the wife?
            
            var isHusband = false
            if let husband = family.husband {
                isHusband = person.personID == husband
            }

            var isWife = false
            if let wife = family.wife {
                isWife = person.personID == wife
            }
            
            if !isHusband && !isWife {
                throw ReportingError.report(person.personID, "not listed as parent")
            }
            
            if isHusband && isWife {
                throw ReportingError.report(person.personID, "listed as both parents")
            }
            
            if whichFamily > 1 {
                result += NL
            }
            // result += "Marriage to "
            if isHusband && family.wife != nil {
                result += "Married to " + personsNameString(family.wife!, showPersonIDs) + NL + NL
            } else if isWife && family.husband != nil {
                result += "Married to " + personsNameString(family.husband!, showPersonIDs) + NL + NL
            }
            
            // Details of the marriage
            
            var marriageResult = ""
            // We're not sure yet that we'll have anything to print.

            if let marriage = family.marriage {
                marriageResult += NL + "    " + marriage.description
            }
            if let beginStatus = family.beginStatus {
                if beginStatus != "Single" {
                    // It's totally uninteresting unless it's not "Single".
                    marriageResult += NL + "    marriage beginning status: "
                        + beginStatus
                }
            }
            if let endStatus = family.endStatus {
                marriageResult += NL + "    marriage ending status: " + endStatus
            }
            if let endEvent = family.endEvent {
                marriageResult += NL + "    marriage end: " + endEvent.description
            }
            
            if marriageResult != "" {
                result += "Marriage:" + marriageResult + NL + NL
            }
            
            // Children
            
            // We want to count only children that have not already been listed, so
            // we have to preprocess the child list.
            var childrenToPrint = [Child]()
            for c in family.children {
                if !childList.contains(c) {
                    childList.append(c)
                    childrenToPrint.append(c)
                }
            }
            
            if childrenToPrint.count == 1 {
                result += "Child:" + NL
            } else if childrenToPrint.count > 1 {
                result += "Children:" + NL
            }
            
            for c in childrenToPrint {
                result += "    " + personsNameString(c.personID, showPersonIDs)
                if isWife {
                    if let mrel = c.relationToMother {
                        if mrel != "" && mrel != "birth" {
                            result += " (\(mrel)-child)"
                        }
                    }
                }
                else if isHusband {
                    if let frel = c.relationToFather {
                        if frel != "" && frel != "birth" {
                            result += " (\(frel)-child)"
                        }
                    }
                }
                result += NL
            }

         }
        // result += NL
        
        return result
    }


    // Return a description of a Person's family relations, with expanded details.

    func personsFamilyDetails(_ person: Person) throws -> String {
        var result = ""

        if let familyC = person.familyC {
            try result += NL + personsFamilyCDetails(person, familyC)
        }
        
        if let familyS = person.familyS {
            try result += NL + personsFamilySDetails(person, familyS)
        }
        
        return result
    }

    // Return the name of the person with the given PersonID, formatted never
    // to be nil and to include, or not, the PersonID depending on the user's
    // whim.

    func personsNameString(_ personID: PersonID, _ showPersonIDS: Bool) -> String {
        let who = ancestry.people[personID]
        var name = "(no name)" // in case no name is available
        if who != nil && who!.names.count > 0 {
            name = who!.names[0].baseName
        }
        if showPersonIDs {
            return "[\(personID)] " + name
        } else {
            return name
        }
    }


    // Return a note, reasonably formatted.

    func formattedNote(_ noteID: NoteID) -> String {
        guard let note = ancestry.notes[noteID] else {
            return ""
        }
        
        var result = ""
        
        result += NL
        for paragraph in note.contents {
            var lineOut = ""
            for word in paragraph.split(separator: " ") {
                if lineOut.count + word.count + 1 > LINE_LENGTH {
                    result += lineOut + NL
                    lineOut = ""
                }
                if lineOut != "" {
                    lineOut += " "
                }
                lineOut += word
            }
            if lineOut != "" {
                result += lineOut + NL
            }
            result += NL
        }
        
        return result
    }

    // Return a list of Notes, suitably formatted.

    func formattedNoteList(_ noteIDs: [NoteID]) -> String {
        if noteIDs.count == 0 {
            return ""
        }
        else if noteIDs.count == 1 {
            return formattedNote(noteIDs[0])
        }
        
        // We have more than one note.
        var result = ""
        
        for noteNum in 0 ..< noteIDs.count {
            result += "Note \(noteNum + 1):" + NL
            result += formattedNote(noteIDs[noteNum]) + NL
        }
        
        return result
    }


    // Return the notes about a Person, reasonably formatted.

    func personNotes(_ person: Person) -> String {
        return formattedNoteList(person.noteIDs)
    }

}

