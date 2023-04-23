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
    
    //MARK: - Fonts
    
    // Size reference: https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/typography
    class var bodySize: CGFloat { return UIFont.preferredFont(forTextStyle: .body).pointSize } // 17pt at default settings
    class var titleSize: CGFloat { return UIFont.preferredFont(forTextStyle: .title2).pointSize } // 22
    class var subtitleSize: CGFloat { return UIFont.preferredFont(forTextStyle: .title3).pointSize } // 20
    class var headlineSize: CGFloat { return UIFont.preferredFont(forTextStyle: .headline).pointSize } // 17
    class var subheadSize: CGFloat { return UIFont.preferredFont(forTextStyle: .subheadline).pointSize } // 15
    class var calloutSize: CGFloat { return UIFont.preferredFont(forTextStyle: .callout).pointSize } // 16
    
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
        button.layer.cornerRadius = buttonCornerRadius
        Style.setButtonInsets(button)
    }
    
    static func styleButton(asOutline button: UIButton, color: UIColor = App.theme.buttonTintColor) {
        button.tintColor = color
        // Setting the borderColor to the currentTitleColor handles the case
        // where the button is disabled.
        button.layer.borderColor = button.currentTitleColor.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = buttonCornerRadius
        Style.setButtonInsets(button)
    }
    
    static func styleButton(asPlain button: UIButton, color: UIColor = App.theme.buttonTintColor) {
        button.tintColor = color
        button.layer.cornerRadius = buttonCornerRadius
        Style.setButtonInsets(button)
    }
    
    // styleButton for an ASButtonNode includes setting the title, because that involves colors
    static func styleButton(asInverse button: ASButtonNode, title: String, fontSize size: CGFloat = Style.bodySize, color: UIColor = App.theme.inverseButtonColor) {
        button.backgroundColor = color
        button.tintColor = .white
        button.cornerRadius = buttonCornerRadius
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        let font = UIFont.systemFont(ofSize: size)
        button.setTitle(title, with: font, with: .white, for: .normal)
        button.setTitle(title, with: font, with: .gray, for: .disabled)
        button.setTitle(title, with: font, with: .gray, for: .highlighted)
    }

    static func styleButton(asOutline button: ASButtonNode, title: String, fontSize size: CGFloat = Style.bodySize, color: UIColor = App.theme.buttonTintColor) {
        button.borderColor = color.cgColor
        button.borderWidth = 1.0
        button.tintColor = color
        button.cornerRadius = buttonCornerRadius
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        let font = UIFont.systemFont(ofSize: size)
        button.setTitle(title, with: font, with: color, for: .normal)
        button.setTitle(title, with: font, with: .gray, for: .disabled)
        button.setTitle(title, with: font, with: .gray, for: .highlighted)
    }

    static func styleButton(asPlain button: ASButtonNode, title: String, fontSize size: CGFloat = Style.bodySize, color: UIColor = App.theme.buttonTintColor) {
        button.tintColor = color
        button.cornerRadius = buttonCornerRadius
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        let font = UIFont.systemFont(ofSize: size)
        button.setTitle(title, with: font, with: color, for: .normal)
        button.setTitle(title, with: font, with: .gray, for: .disabled)
        button.setTitle(title, with: font, with: .gray, for: .highlighted)
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
    
//    static func makeTableHeaderString(_ str: String, size: CGFloat = 16) -> NSAttributedString {
//        let attrs = [
//            NSAttributedString.Key.foregroundColor: Style.secondaryLabelColor,
//            NSAttributedString.Key.font: UIFont.systemFont(ofSize: size, weight: .light).withSmallCaps]
//        return NSAttributedString(string: str, attributes: attrs)
//    }
    
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
    
    static func makeMultilineString(_ str: String, ofSize size: CGFloat = 14) -> NSAttributedString {
        let attrs = [
            NSAttributedString.Key.foregroundColor: Style.labelColor,
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
    
    static func setupTitle(_ textNode: ASTextNode, str: String, ofSize size: CGFloat = titleSize, maxNumLines: UInt = 2) {
        textNode.attributedText = makeTitleString(str, ofSize: size)
        textNode.maximumNumberOfLines = maxNumLines
        textNode.truncationMode = .byWordWrapping
    }
    
    static func setupSubtitle(_ textNode: ASTextNode, str: String, ofSize size: CGFloat = subtitleSize) {
        textNode.attributedText = makeSubtitleString(str, ofSize: size)
        textNode.maximumNumberOfLines = 1
        textNode.truncationMode = .byTruncatingTail
    }

//    static func setupMultilineText(_ textNode: ASTextNode, str: String, ofSize size: CGFloat) {
//        textNode.attributedText = makeSubtitleString(str, ofSize: size)
//        textNode.maximumNumberOfLines = 0
//    }

//    static func setupSynopsisText(_ textNode: ASTextNode, str: String, ofSize size: CGFloat) {
//        textNode.attributedText = makeMultilineString(str, ofSize: size)
//        textNode.maximumNumberOfLines = 0
//    }
}
