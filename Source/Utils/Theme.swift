//
//  Style.swift
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

protocol Theme {
    var foregroundColor: UIColor { get }
    var backgroundColor: UIColor { get }
//    var backgroundDark1: UIColor { get }
    var backgroundDark2: UIColor { get }
//    var backgroundDark3: UIColor { get }
//    var backgroundDark4: UIColor { get }
    var backgroundDark5: UIColor { get }
//    var backgroundDark6: UIColor { get }
//    var backgroundDark7: UIColor { get }
//    var backgroundDark8: UIColor { get }
    
    var tableHeaderForeground: UIColor { get }
    var tableHeaderBackground: UIColor { get }
}

