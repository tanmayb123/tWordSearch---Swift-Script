//
//  main.swift
//  wordsearchsolver
//
//  Created by Tanmay Bakshi on 2017-04-14.
//  Copyright © 2017 Tanmay Bakshi. All rights reserved.
//

import Foundation

// Boyer-Moore String Search from Ray Wenderlich
extension String {
    func index(of pattern: String, usingHorspoolImprovement: Bool = false) -> Index? {
        // Cache the length of the search pattern because we're going to
        // use it a few times and it's expensive to calculate.
        let patternLength = pattern.characters.count
        guard patternLength > 0, patternLength <= characters.count else { return nil }
        
        // Make the skip table. This table determines how far we skip ahead
        // when a character from the pattern is found.
        var skipTable = [Character: Int]()
        for (i, c) in pattern.characters.enumerated() {
            skipTable[c] = patternLength - i - 1
        }
        
        // This points at the last character in the pattern.
        let p = pattern.index(before: pattern.endIndex)
        let lastChar = pattern[p]
        
        // The pattern is scanned right-to-left, so skip ahead in the string by
        // the length of the pattern. (Minus 1 because startIndex already points
        // at the first character in the source string.)
        var i = index(startIndex, offsetBy: patternLength - 1)
        
        // This is a helper function that steps backwards through both strings
        // until we find a character that doesn’t match, or until we’ve reached
        // the beginning of the pattern.
        func backwards() -> Index? {
            var q = p
            var j = i
            while q > pattern.startIndex {
                j = index(before: j)
                q = index(before: q)
                if self[j] != pattern[q] { return nil }
            }
            return j
        }
        
        // The main loop. Keep going until the end of the string is reached.
        while i < endIndex {
            let c = self[i]
            
            // Does the current character match the last character from the pattern?
            if c == lastChar {
                
                // There is a possible match. Do a brute-force search backwards.
                if let k = backwards() { return k }
                
                if !usingHorspoolImprovement {
                    // If no match, we can only safely skip one character ahead.
                    i = index(after: i)
                } else {
                    // Ensure to jump at least one character (this is needed because the first
                    // character is in the skipTable, and `skipTable[lastChar] = 0`)
                    let jumpOffset = max(skipTable[c] ?? patternLength, 1)
                    i = index(i, offsetBy: jumpOffset, limitedBy: endIndex) ?? endIndex
                }
            } else {
                // The characters are not equal, so skip ahead. The amount to skip is
                // determined by the skip table. If the character is not present in the
                // pattern, we can skip ahead by the full pattern length. However, if
                // the character *is* present in the pattern, there may be a match up
                // ahead and we can't skip as far.
                i = index(i, offsetBy: skipTable[c] ?? patternLength, limitedBy: endIndex) ?? endIndex
            }
        }
        return nil
    }
    
    func minCharacters(min: Int) -> String {
        var newString = self
        while newString.characters.count < min {
            newString = " " + newString
        }
        return newString
    }
    
    func minCharactersLeft(min: Int) -> String {
        var newString = self
        while newString.characters.count < min {
            newString = newString + " "
        }
        return newString
    }
}

// Implementation of Word Search algorithm by John O'Hagan
var matrix_ = try! String(contentsOfFile: CommandLine.arguments[1])
var wordlist_ = try! String(contentsOfFile: CommandLine.arguments[2])

matrix_ = matrix_.replacingOccurrences(of: "0", with: "O")
matrix_ = matrix_.replacingOccurrences(of: "@", with: "O")
matrix_ = matrix_.replacingOccurrences(of: " ", with: "")
var matrix = matrix_.components(separatedBy: NSCharacterSet.newlines).filter({!$0.isEmpty}).joined(separator: "\n")
wordlist_ = wordlist_.replacingOccurrences(of: " ", with: "")
wordlist_ = wordlist_.components(separatedBy: NSCharacterSet.newlines).filter({!$0.isEmpty}).joined(separator: "\n")
var wordlist = wordlist_.components(separatedBy: "\n")
var length = matrix.components(separatedBy: "\n")[0].characters.count + 1

var letters: [(String, Int, Int)] = []
for (index, letter) in matrix.characters.enumerated() {
    letters.append((String(letter), Int(index / length), Int(Double(index).truncatingRemainder(dividingBy: Double(length)))))
}

var lines: [String: [(String, Int, Int)]] = [:]
var offsets = ["down": 0, "rt dn": 1, "lt dn": -1]
for (direction, offset) in offsets {
    lines[direction] = []
    for i in 0...length {
        var index = i
        while index < letters.count {
            lines[direction]!.append(letters[index])
            index += length + offset
        }
    }
}
lines["left"] = letters.reversed()
lines["right"] = letters
lines["up"] = lines["down"]!.reversed()
lines["lt up"] = lines["rt dn"]!.reversed()
lines["rt up"] = lines["lt dn"]!.reversed()

var coordColors: [(Int, Int)] = []
for (direction, tuple) in lines {
    var string = ""
    for i in tuple {
        string += i.0
    }
    for word in wordlist {
        if string.contains(word) {
            var location = tuple[string.distance(from: string.startIndex, to: string.index(of: word)!)]
            // Custom code starts here
            let row = location.1
            let col = location.2
            var rowString = "\(row + 1)".minCharacters(min: 3)
            var colString = "\(col + 1)".minCharacters(min: 3)
            var directionString = "\(direction)".minCharactersLeft(min: 5)
            print("   \(rowString)  \(colString)  \(directionString)  \(word)")
            coordColors.append((row, col))
            var tempRow = row
            var tempCol = col
            for i in 1...word.characters.count-1 {
                tempRow += direction.contains("d") ? 1 : direction.contains("u") ? -1 : 0
                tempCol += direction.contains("r") ? 1 : direction.contains("l") ? -1 : 0
                coordColors.append((tempRow, tempCol))
            }
        }
    }
}

var printString = " "
for (index, i) in letters.enumerated() {
    var printedColor = false
    for j in coordColors {
        if i.1 == j.0 && i.2 == j.1 {
            printedColor = true
            printString += i.0.bold.yellow
            break
        }
    }
    if !printedColor {
        printString += i.0
    }
    if index == length - 1 {
        printString += "\n"
    }
    printString += " "
}
print(printString.replacingOccurrences(of: "\n\n", with: "\n"))
