#  `readgedcom`
## A command-line reader for GEDCOM files
[GEDCOM](https://www.gedcom.org) is a standard specifying the structure of
export files from genealogical programs such as
[Gramps](https://gramps-project.org/blog/).

You shouldn't be reading export files.

They exist to help you move data from one program to another, and are not
exactly human-friendly even though they're text-only.
But I can think of a couple of reasons why you might need to look at a GEDCOM
file:

1. You're using one genealogical program, GP1,
and your cousin Susan is using another, GP2.
You want to exchange family trees with Susan,
but GP1 and GP2 refuse to read each other's GEDCOM exports.

2. Your father died leaving his genealogical files on a PC running Windows ME.
You want to respect his work, but your willingness to deal with genealogy
extends only to freeware on macOS. Your freeware (hi, Gramps!) does not like
Dad's old GEDCOM files.

3. Your relatives (apart from Susan) aren't interested in genealogical
programs. They just want a printed list of their ancestors' names and dates.

4. There must be something I didn't think of.

[Guess which is me.]

###What you get from `readgedcom`
It reads a good deal but not all of the
[GEDCOM standard](https://www.gedcom.org/gedcom.html).
I had only one example to use as test input, and while the example had a good
deal of variety, it wasn't a test case for the entire standard.

So here's how to use `readgedcom`:

0. Download the project from Github.
It's a program written in Swift for macOS. The easiest way to work with it
is with Xcode. If any of that sounds foreign to you, you need help
— unless you really want to learn those things for yourself.
(I did, but I've probably been programming for longer than you have.)

1. Build the program with Xcode, and run it like this in the Terminal app (or
equivalent):

        readgedcom inputFileName > outputFileName

   The file called "inputFileName" should already exist.
   The file called "outputFileName" should not already exist, unless you're
   willing to have it overwritten. It's a readable text summary of
   inputFileName.

   On the error output, you get first a bunch of error messages and then a
   summary of how many lines were read, how many people were described, etc.

2. Now you need to get rid of the error messages.
They are caused by:

   (a) Parts of the input file that don't conform to the GEDCOM standard.
   The standard changes, slowly, and your input file might need to be
   modified to conform to the current GEDCOM.
   Proceed carefully! Remember, those files aren't designed for humans,
   so you need to be super-fussy about details.
   
   (b) Parts of GEDCOM that `readgedcom` doesn't understand. 
   For these problems, you need to fix the program.

For problems of type (a), your job is to fix the input file, with
the help of whatever readable text `readgedcom` is willing to print,
plus the error messages.

For problems of type (b), you need to fix the program so that it knows more
about GEDCOM. It's not a terribly complex program, and I've tried to make it
go step by step, but ... if you've done this kind of thing before, you know
it can be hard.

I wish you luck, and I'm willing to help by clarke@cs.utoronto.ca
[email](mailto:clarke@cs.utoronto.ca).
