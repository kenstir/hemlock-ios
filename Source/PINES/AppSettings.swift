//
//  AppSettings.swift
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

import UIKit
import Valet

//todo make this a protocol
struct AppSettings {

    //MARK: - Consortium Properties

    static let appTitle = "PINES"
    static let url = "https://gapines.org"
    
    //MARK: - Theme Properties

    static let themeForegroundColor = UIColor.white
    static let themeBackgroundColor = UIColor(red: 0x37/0xff, green: 0x96/0xff, blue: 0x76/0xff, alpha: 1.0)
    static let themeBackgroundDark1 = UIColor(red: 0x32/0xff, green: 0x89/0xff, blue: 0x6c/0xff, alpha: 1.0)
    static let themeBackgroundDark2 = UIColor(red: 0x2e/0xff, green: 0x7b/0xff, blue: 0x61/0xff, alpha: 1.0)
    static let themeBackgroundDark3 = UIColor(red: 0x29/0xff, green: 0x6e/0xff, blue: 0x56/0xff, alpha: 1.0)
    static let themeBackgroundDark4 = UIColor(red: 0x23/0xff, green: 0x60/0xff, blue: 0x4c/0xff, alpha: 1.0)
    static let themeBackgroundDark5 = UIColor(red: 0x1e/0xff, green: 0x52/0xff, blue: 0x41/0xff, alpha: 1.0)
    static let themeBackgroundDark6 = UIColor(red: 0x19/0xff, green: 0x45/0xff, blue: 0x36/0xff, alpha: 1.0)
    static let themeBackgroundDark7 = UIColor(red: 0x14/0xff, green: 0x37/0xff, blue: 0x2b/0xff, alpha: 1.0)
    static let themeBackgroundDark8 = UIColor(red: 0x0f/0xff, green: 0x29/0xff, blue: 0x21/0xff, alpha: 1.0)
    
    //MARK: - App State

    static var idlParserStatus: Bool?
    static var account: Account?
    static let valet = Valet.valet(with: Identifier(nonEmpty: "Hemlock")!, accessibility: .whenUnlockedThisDeviceOnly)

}
