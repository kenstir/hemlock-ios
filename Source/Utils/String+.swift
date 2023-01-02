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
}
