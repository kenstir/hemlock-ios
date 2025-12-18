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

extension UIButton {
    // Setting a title of nil does not clear existing titles
    func setTitleEx(_ titleIn: String?) {
        // Looping over all states is not necessary.
//        let states: [UIControl.State] = [.normal, .highlighted, .disabled, .selected, .focused, .application, .reserved]
//        for state in states { self.setTitle(title, for: state) }

        let title = titleIn ?? ""
        self.setTitle(title, for: .normal)

        // Also unnecessary: updating self.configuration, and setNeedsLayout()
    }
}
