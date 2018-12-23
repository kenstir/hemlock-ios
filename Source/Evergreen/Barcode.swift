//
//  Barcode.swift
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

enum BarcodeFormat {
    case Disabled  // feature is disabled for this consortium
    case Codabar14 // Codabar with check digit
}

class Barcode {
    /// return default barcode value for the given format
    static public func defaultValue(format: BarcodeFormat) -> String {
        switch format {
        case .Disabled:
            return ""
        case .Codabar14:
            return "00000000000000"
        }
    }

    /// format label in the usual way for the given format
    static public func displayLabel(_ str: String, format: BarcodeFormat) -> String {
        switch format {
        case .Disabled:
            return ""
        case .Codabar14:
            guard str.count == 14 else { return str }
            var s = str[0..<1]
            s = s + " " + str[1..<5]
            s = s + " " + str[5..<9]
            s = s + " " + str[9..<13]
            s = s + " " + str[13..<14]
            return s
        }
    }
    
    /// validate codabar, because it's hard/impossible to catch
    /// objc NSInvalidArgumentException from Swift
    static public func isValid(_ str: String, format: BarcodeFormat) -> Bool {
        switch format {
        case .Disabled:
            return true
        case .Codabar14:
            guard str.count == 14 else { return false }
            let pattern = "^[0123456789]+$" // or "^\\d{14}$"
            let range = str.range(of: pattern, options: .regularExpression)
            return (range != nil)
        }
    }
}