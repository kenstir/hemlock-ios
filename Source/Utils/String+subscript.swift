//
//  String+splitOnRegex.swift

import Foundation

// String extension from
// https://stackoverflow.com/a/46133083/3157570
// implicitly released under the CC by-SA license
extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let idx1 = index(startIndex, offsetBy: max(0, range.lowerBound))
        let idx2 = index(startIndex, offsetBy: min(self.count, range.upperBound))
        return String(self[idx1..<idx2])
    }
}
