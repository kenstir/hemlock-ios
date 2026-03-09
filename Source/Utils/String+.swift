//
//  String+.swift
//
//  Copyright (C) 2018 Kenneth H. Cox
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

import Foundation

/// Error that can be thrown by `String.expandTemplate(values:)`
enum TemplateError: Error {
    case missingValue(key: String, template: String)
}
extension TemplateError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingValue(let key, let template):
            return "Missing value for key \"\(key)\" in template \"\(template)\""
        }
    }
}

extension String {
    func split(onString separator: String) -> [String] {
        return self.components(separatedBy: separator)
    }

    func trimQuotes() -> String {
        return self.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }

    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    func trimTrailing(_ suffixChar: Character) -> String {
        var s = self
        let suffix = "" + [suffixChar]
        while s.hasSuffix(suffix) {
            s = "" + s.dropLast()
        }
        return s
    }

    func removePrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }

    /// Returns a string with tokens of the form `{key}` replaced with the corresponding value from `values`.
    ///
    /// - Throws: `TemplateError.missingValue(key:)` if a key in the template is not present in the map.
    func expandTemplate(values: [String: String]) throws -> String {
        let pattern = "\\{([a-zA-Z0-9_]+)\\}"
        let regex = try NSRegularExpression(pattern: pattern)
        let ns = self as NSString
        let matches = regex.matches(in: self, range: NSRange(location: 0, length: ns.length))

        // Replace from the end so earlier ranges are not invalidated by mutations
        let result = NSMutableString(string: self)
        for match in matches.reversed() {
            guard match.numberOfRanges > 1 else { continue }
            let keyRange = match.range(at: 1)
            let key = ns.substring(with: keyRange)
            guard let replacement = values[key] else {
                throw TemplateError.missingValue(key: key, template: self)
            }
            result.replaceCharacters(in: match.range, with: replacement)
        }

        return result as String
    }
}
