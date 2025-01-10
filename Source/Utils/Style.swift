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
    
    //MARK: - Fonts
    
    // Size reference: https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/typography
    class var titleSize: CGFloat { return UIFont.preferredFont(forTextStyle: .title2).pointSize } // 22
    class var subtitleSize: CGFloat { return UIFont.preferredFont(forTextStyle: .title3).pointSize } // 20
    class var headlineSize: CGFloat { return UIFont.preferredFont(forTextStyle: .headline).pointSize } // 17
    class var bodySize: CGFloat { return UIFont.preferredFont(forTextStyle: .body).pointSize } // 17pt at default settings
    class var calloutSize: CGFloat { return UIFont.preferredFont(forTextStyle: .callout).pointSize } // 16
    class var subheadSize: CGFloat { return UIFont.preferredFont(forTextStyle: .subheadline).pointSize } // 15
    class var footnoteSize: CGFloat { return UIFont.preferredFont(forTextStyle: .footnote).pointSize} // 13
    class var caption1Size: CGFloat { return UIFont.preferredFont(forTextStyle: .caption1).pointSize} // 12
    class var caption2Size: CGFloat { return UIFont.preferredFont(forTextStyle: .caption2).pointSize} // 11

    //MARK: - Sizes

    static var tableHeaderHeight = 55.0
    static let buttonCornerRadius = 6.0

    //MARK: - Colors
    
    class var systemBackground: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.systemBackground
        } else {
            return UIColor.white
        }
    }
    
    class var systemGroupedBackground: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.systemGroupedBackground
        } else {
            return UIColor.groupTableViewBackground
        }
    }
    
    class var secondarySystemGroupedBackground: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.secondarySystemGroupedBackground
        } else {
            return UIColor.white
        }
    }

    class var labelColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.label
        } else {
            return UIColor.black
        }
    }
    
    class var secondaryLabelColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.secondaryLabel
        } else {
            return UIColor.darkGray
        }
    }
    
    class var tertiaryLabelColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.tertiaryLabel
        } else {
            return UIColor.darkGray
        }
    }
    
    class var separatorColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.separator
        } else {
            return UIColor.lightGray
        }
    }

    //MARK: - ActivityIndicator
    
    static func styleActivityIndicator(_ activityIndicator: UIActivityIndicatorView, color: UIColor = App.theme.buttonTintColor) {
        activityIndicator.color = color
    }
    
    //MARK: - AlertController
    
    static func styleAlertController(_ alertController: UIAlertController) {
        // if you customize this, verify adequate contrast in dark mode
    }
    
    //MARK: - BarButtonItem
    
    static func styleBarButton(_ button: UIBarButtonItem) {
        button.tintColor = App.theme.barTextForegroundColor
    }

    //MARK: - Button

    static private func setButtonInsets(_ button: UIButton) {
        if #available(iOS 15.0, *) {
            button.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
        } else {
            button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        }
    }

    static func styleButton(asInverse button: UIButton, color: UIColor = App.theme.inverseButtonColor) {
        button.backgroundColor = color
        button.tintColor = .white
        // Setting borderColor here improves an edge case where we style the Place Hold button
        // asOutline when disabling it.
        button.layer.borderColor = button.currentTitleColor.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = buttonCornerRadius
        Style.setButtonInsets(button)
    }
    
    static func styleButton(asOutline button: UIButton, color: UIColor = App.theme.buttonTintColor) {
        button.backgroundColor = nil
        button.tintColor = color
        // Setting the borderColor to the currentTitleColor handles the case
        // where the button is disabled.
        button.layer.borderColor = button.currentTitleColor.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = buttonCornerRadius
        Style.setButtonInsets(button)
    }
    
    static func styleButton(asPlain button: UIButton, color: UIColor = App.theme.buttonTintColor) {
        button.backgroundColor = nil
        button.tintColor = color
        button.layer.cornerRadius = buttonCornerRadius
        Style.setButtonInsets(button)
    }

    //MARK: - SearchBar

    static func styleSearchBar(_ searchBar: UISearchBar) {
        searchBar.tintColor = App.theme.buttonTintColor
        searchBar.backgroundColor = systemBackground
    }
    
    //MARK: - SegmentedControl
    
//    static func styleSegmentedControl(_ v: UISegmentedControl) {
//        v.tintColor = App.theme.buttonTintColor
//    }
    
    //MARK: - Table Header

    static func styleLabel(asTableHeader v: UILabel) {
        v.textColor = Style.secondaryLabelColor
        v.backgroundColor = Style.systemGroupedBackground
        v.font = UIFont.systemFont(ofSize: calloutSize, weight: .light).withSmallCaps
    }

    static func styleView(asTableHeader v: UIView) {
        v.backgroundColor = Style.systemGroupedBackground
    }

    static func styleStackView(asTableHeader v: UIView) {
        let bgView = UIView()
        bgView.backgroundColor = Style.systemGroupedBackground
        bgView.translatesAutoresizingMaskIntoConstraints = false
        v.insertSubview(bgView, at: 0)
        bgView.pin(to: v)
    }
    
    //MARK: - Attributed Strings

    static func makeTitleString(_ str: String, ofSize size: CGFloat = 16) -> NSAttributedString {
        let attrs = [
            NSAttributedString.Key.foregroundColor: Style.labelColor,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: size, weight: .semibold)]
        return NSAttributedString(string: str, attributes: attrs)
    }

    static func makeSubtitleString(_ str: String, ofSize size: CGFloat = 14) -> NSAttributedString {
        let attrs = [
            NSAttributedString.Key.foregroundColor: Style.secondaryLabelColor,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: size)]
        return NSAttributedString(string: str, attributes: attrs)
    }

    static func makeString(_ str: String, ofSize size: CGFloat = 16) -> NSAttributedString {
        let attrs = [
            NSAttributedString.Key.foregroundColor: Style.labelColor,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: size, weight: .regular)]
        return NSAttributedString(string: str, attributes: attrs)
    }
}
