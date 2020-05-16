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
import AsyncDisplayKit

class Style {
    
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
    
    static func styleActivityIndicator(_ activityIndicator: UIActivityIndicatorView, color: UIColor = App.theme.primaryDark2Color) {
        activityIndicator.color = color
    }
    
    //MARK: - AlertController
    
    static func styleAlertController(_ alertController: UIAlertController) {
        // avoie: this causes low contrast in dark mode
        //alertController.view.tintColor = App.theme.primaryDark2Color
    }
    
    //MARK: - BarButtonItem
    
    static func styleBarButton(_ button: UIBarButtonItem) {
        button.tintColor = App.theme.barTextForegroundColor
    }

    static func styleBarButton(asPlain button: UIBarButtonItem) {
        button.tintColor = App.theme.primaryDark2Color
    }

    //MARK: - Button

    static func styleButton(asInverse button: UIButton, color: UIColor = App.theme.primaryColor) {
        button.backgroundColor = color
        button.tintColor = .white
        button.layer.cornerRadius = 6
    }
    
    static func styleButton(asInverse button: ASButtonNode, color: UIColor = App.theme.primaryColor) {
        button.backgroundColor = color
        button.tintColor = .white
        button.cornerRadius = 6
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }
    
    static func styleButton(asOutline button: UIButton, color: UIColor = App.theme.primaryDarkColor) {
        button.tintColor = color
        // Setting the borderColor to the currentTitleColor handles the case
        // where the button is disabled.
        button.layer.borderColor = button.currentTitleColor.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 6
    }
    
    static func styleButton(asPlain button: UIButton, color: UIColor = App.theme.primaryDarkColor) {
        button.tintColor = color
        button.layer.cornerRadius = 6
    }

    static func setButtonTitle(_ button: ASButtonNode, title: String, fontSize size: CGFloat = 17) {
        let font = UIFont.systemFont(ofSize: size)
        button.setTitle(title, with: font, with: .white, for: .normal)
        button.setTitle(title, with: font, with: .gray, for: .disabled)
        button.setTitle(title, with: font, with: .gray, for: .highlighted)
    }
    
    //MARK: - SearchBar

    static func styleSearchBar(_ searchBar: UISearchBar) {
        searchBar.tintColor = App.theme.primaryDarkColor
        searchBar.backgroundColor = systemBackground
    }
    
    //MARK: - SegmentedControl
    
    static func styleSegmentedControl(_ v: UISegmentedControl) {
        v.tintColor = App.theme.primaryDarkColor
    }
    
    //MARK: - Table Header

    static func styleLabel(asTableHeader v: UILabel) {
        v.textColor = Style.secondaryLabelColor
        v.font = UIFont.systemFont(ofSize: 16, weight: .light).withSmallCaps
    }

    static func styleStackView(asTableHeader v: UIView) {
        let bgView = UIView()
        bgView.backgroundColor = Style.systemGroupedBackground
        bgView.translatesAutoresizingMaskIntoConstraints = false
        v.insertSubview(bgView, at: 0)
        bgView.pin(to: v)
    }
    
    //MARK: - Attributed Strings
    
    static func makeTableHeaderString(_ str: String) -> NSAttributedString {
        let attrs = [
            NSAttributedString.Key.foregroundColor: Style.secondaryLabelColor,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .light).withSmallCaps]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
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
    
    //MARK: - ASTextNode
    
    static func setupTitle(_ textNode: ASTextNode, str: String, ofSize size: CGFloat = 18) {
        textNode.attributedText = makeTitleString(str, ofSize: size)
        textNode.maximumNumberOfLines = 2
        textNode.truncationMode = .byWordWrapping
    }
    
    static func setupSubtitle(_ textNode: ASTextNode, str: String, ofSize size: CGFloat = 16) {
        textNode.attributedText = makeSubtitleString(str, ofSize: size)
        textNode.maximumNumberOfLines = 1
        textNode.truncationMode = .byTruncatingTail
    }

    static func setupMultilineText(_ textNode: ASTextNode, str: String, ofSize size: CGFloat) {
        textNode.attributedText = makeSubtitleString(str, ofSize: size)
        textNode.maximumNumberOfLines = 0
    }
}
