//
//  Copyright (c) 2025 Kenneth H. Cox
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
//  along with this program; if not, see <https://www.gnu.org/licenses/>.

import UIKit

protocol Theme {
    var barBackgroundColor: UIColor { get }
    var barTextForegroundColor: UIColor { get }

    var accentColor: UIColor { get }
    var filledButtonColor: UIColor { get }
    var mainButtonTintColor: UIColor { get }

    var alertTextColor: UIColor { get }
    var warningTextColor: UIColor { get }
}

class BaseTheme: Theme {
    var barBackgroundColor: UIColor { return UIColor.darkGray }
    var barTextForegroundColor: UIColor { return UIColor.white }

    var accentColor: UIColor { return UIColor(named: "accentColor")! }
    var filledButtonColor: UIColor { return UIColor(named: "filledButtonColor")! }
    var mainButtonTintColor: UIColor { return UIColor(named: "mainButtonTintColor") ?? UIColor(named: "accentColor")! }

    var alertTextColor: UIColor { UIColor(named: "alertTextColor")! }
    var warningTextColor: UIColor { UIColor(named: "warningTextColor")! }
}
