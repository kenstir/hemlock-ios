//
//  BarcodeUtils.swift
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
import ZXingObjC

enum BarcodeFormat {
    case Disabled  // feature is disabled for this consortium
    case Codabar
    case Code39
}

class BarcodeUtils {
    static public func toZXFormat(_ format: BarcodeFormat) -> ZXBarcodeFormat {
        switch format {
        case .Code39:
            return kBarcodeFormatCode39
        default:
            return kBarcodeFormatCodabar
        }
    }

    /// return default barcode value for the given format
    static public func defaultValue(format: BarcodeFormat) -> String {
        switch format {
        case .Disabled:
            return ""
        case .Codabar:
            return "00000000000000"
        case .Code39:
            return "D000000000"
        }
    }

    /// format label in the usual way for the given format
    static public func displayLabel(_ str: String, format: BarcodeFormat) -> String {
        switch format {
        case .Disabled:
            return ""
        case .Codabar:
            switch str.count {
            case 14:
                var s = str[0..<1]
                s = s + " " + str[1..<5]
                s = s + " " + str[5..<9]
                s = s + " " + str[9..<13]
                s = s + " " + str[13..<14]
                return s
            default:
                return str
            }
        case .Code39:
            return str
        }
    }
    
    /// encode barcode using the given format, return nil if it fails
    static public func tryEncode(_ barcode: String, width: Int32, height: Int32, format: BarcodeFormat) -> ZXBitMatrix? {
        let writer = ZXMultiFormatWriter()
        let zxFormat = BarcodeUtils.toZXFormat(format)
        let matrix = writer.safeEncode(barcode, format: zxFormat, width: width, height: height)
        return matrix
    }
}
