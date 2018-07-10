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

class Style {
    
    //MARK: - ActivityIndicator
    
    static func styleActivityIndicator(_ activityIndicator: UIActivityIndicatorView, color: UIColor = App.theme.backgroundDark5) {
        activityIndicator.color = color
    }
    
    //MARK: - BarButtonItem
    
    static func styleBarButton(_ button: UIBarButtonItem) {
        button.tintColor = App.theme.foregroundColor
    }

    static func styleBarButton(asPlain button: UIBarButtonItem) {
        button.tintColor = App.theme.backgroundDark5
    }

    //MARK: - Button

    static func styleButton(asInverse button: UIButton, color: UIColor = App.theme.backgroundColor) {
        button.backgroundColor = color
        button.tintColor = .white
        button.layer.cornerRadius = 6
    }
    
    static func styleButton(asOutline button: UIButton, color: UIColor = App.theme.backgroundDark2) {
        button.tintColor = color
        // Setting the borderColor to the currentTitleColor handles the case
        // where the button is disabled.
        button.layer.borderColor = button.currentTitleColor.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 6
    }
    
    static func styleButton(asPlain button: UIButton, color: UIColor = App.theme.backgroundDark2) {
        button.tintColor = color
        button.layer.cornerRadius = 6
    }
    
    //MARK: - SearchBar

    static func styleSearchBar(_ searchBar: UISearchBar) {
        searchBar.tintColor = App.theme.backgroundDark2
    }
    
    //MARK: - SegmentedControl
    
    static func styleSegmentedControl(_ v: UISegmentedControl) {
        v.tintColor = App.theme.backgroundDark2
    }
    
    //MARK: - Table Header

    static func styleLabel(asTableHeader v: UILabel) {
        v.textColor = UIColor.darkGray
        //TODO: make small caps
        // see also https://liamnichols.github.io/2016/09/11/using-small-caps-in-uikit.html
        // see also https://developer.apple.com/documentation/uikit/uifontdescriptor/attributename/1616701-featuresettings
    }

    static func styleStackView(asTableHeader v: UIView) {
        let bgView = UIView()
        bgView.backgroundColor = App.theme.tableHeaderBackground
        bgView.translatesAutoresizingMaskIntoConstraints = false
        v.insertSubview(bgView, at: 0)
        bgView.pin(to: v)
    }
}
