//
//  UIView+.swift
//
//  Copyright (C) 2024 Kenneth H. Cox
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

// with help from https://stackoverflow.com/questions/13836606/use-table-view-disclosure-indicator-style-for-uibutton-ios
// implicitly released under the CC by-SA license
extension UIView {
    /// add a disclosure indicator to a view ideally a UITextView with .round borderStyle
    func addDisclosureIndicator() {
        if #available(iOS 13.0, *) {
            // create and size a chevron image view
            let configuration = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            let view = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: configuration))
            view.tintColor = .lightGray
            view.contentMode = .scaleAspectFit
            NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 17.0/10.0, constant: 0).isActive = true
            view.translatesAutoresizingMaskIntoConstraints = false

            // overload the image view on the right side of this view
            self.addSubview(view)
            view.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8.0).isActive = true
            view.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        }
    }
}
