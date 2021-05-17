#  `readgedcom`
This is a macOS command-line application that can read (much of) a GEDCOM-formatted genealogical export file and prints a simple version of the contents. If you have a copy of a genealogical file created by a program you don't have, this might help.

I wrote this program to get the useful genealogical information from a set of files that my father worked pretty hard on in the years before he died. Sadly, he was a Windows user, and I'm a Mac user, and I wasn't going to buy an ancient Windows machine to run his ancient Windows files. Filial piety only gets you so far.

I'll explain ... but first: I'm not a genealogist myself, even though I'm in the old-guy demographic where genealogy begins to be fascinating. But if you want to ask me about this program or related issues, I'll be happy to try to help.

##Huh?
Let me explain some of that first paragraph.

- *macOS command-line application* -- you have to type the names of the program name and the file you want it to read, in the Terminal app (or equivalent) on a Macintosh computer.

    And you have to assemble the file yourself. It's in an Xcode project that you should be able to download and build if you're used to that kind of thing, but if you're not ... you'll need a friend who is.

- *export files*: genealogical programs (such as the free Gramps) can "export" the information in their databases to text files that are close to unreadable for humans but that other programs can read ... such as this program.

- *GEDCOM*: a standard format for export files. A standard is needed so that when your cousin maintains a family genealogy but you use a program that's not the one she uses, she can make an export file and your program can read it.

    You can read about GEDCOM at [gedcom.org](https://www.gedcom.org).

- "Many record types": it can't read all GEDCOM records -- just the ones I found in my father's files. But judging by the GEDCOM documentation, their coverage is pretty good.