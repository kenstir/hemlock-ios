//
//  String+splitOnRegex.swift

import Foundation

// String extension to split by regex from
// https://stackoverflow.com/questions/25818197/how-to-split-a-string-in-swift
// implicitly released under the CC by-SA license
extension String {
    func split(regex pattern: String) -> [String] {
        
        guard let re = try? NSRegularExpression(pattern: pattern, options: [])
            else { return [] }
        
        let nsString = self as NSString // needed for range compatibility
        let stop = "<SomeStringThatYouDoNotExpectToOccurInSelf>"
        let modifiedString = re.stringByReplacingMatches(
            in: self,
            options: [],
            range: NSRange(location: 0, length: nsString.length),
            withTemplate: stop)
        return modifiedString.components(separatedBy: stop)
    }

    func replace(regex pattern: String, with: String) -> String {
        guard let re = try? NSRegularExpression(pattern: pattern, options: []) else { return self }

        let nsString = self as NSString
        return re.stringByReplacingMatches(in: self, range: NSRange(location: 0, length: nsString.length), withTemplate: with)
    }
}
