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
    static var tableHeaderHalfHeight = tableHeaderHeight / 2.0
    static let buttonCornerRadius = 6.0

    // Custom insets for a plain button so that the text aligns with other items in a VStack
    static let trimmedLeadingInsets = NSDirectionalEdgeInsets(top: 7, leading: 0.1, bottom: 7, trailing: 0.1)
    static let wideInsets = NSDirectionalEdgeInsets(top: 7, leading: 56, bottom: 7, trailing: 56)
    static let extraWideInsets = NSDirectionalEdgeInsets(top: 7, leading: 56, bottom: 7, trailing: 56)

    //MARK: - Colors

    class var systemBackground: UIColor {
        return UIColor.systemBackground
    }

    class var systemGroupedBackground: UIColor {
        return UIColor.systemGroupedBackground
    }

    class var secondarySystemGroupedBackground: UIColor {
        return UIColor.secondarySystemGroupedBackground
    }

    class var labelColor: UIColor {
        return UIColor.label
    }

    class var secondaryLabelColor: UIColor {
        return UIColor.secondaryLabel
    }

    class var tertiaryLabelColor: UIColor {
        return UIColor.tertiaryLabel
    }

    class var separatorColor: UIColor {
        return UIColor.separator
    }

    //MARK: - ActivityIndicator

    static func styleActivityIndicator(_ activityIndicator: UIActivityIndicatorView) {
        //activityIndicator.color = App.theme.accentColor
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

    static func styleButton(asInverse button: UIButton, withContentInsets insets: NSDirectionalEdgeInsets? = nil) {
        guard button.configuration == nil else { return }

        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = App.theme.filledButtonColor
        if let insets = insets {
            config.contentInsets = insets
        }
        button.configuration = config
        button.setNeedsUpdateConfiguration()
    }

    static func styleButton(asOutline button: UIButton, withContentInsets insets: NSDirectionalEdgeInsets? = nil) {
        guard button.configuration == nil else { return }

        var config = UIButton.Configuration.gray()
        if let insets = insets {
            config.contentInsets = insets
        }
        button.configuration = config
        button.setNeedsUpdateConfiguration()
    }

    static func styleButton(asPlain button: UIButton, withContentInsets insets: NSDirectionalEdgeInsets? = nil) {
        guard button.configuration == nil else { return }

        var config = UIButton.Configuration.plain()
        if let insets = insets {
            config.contentInsets = insets
        }
        button.configuration = config
        button.setNeedsUpdateConfiguration()
    }

    //MARK: - SearchBar

    static func styleSearchBar(_ searchBar: UISearchBar) {
        searchBar.tintColor = App.theme.accentColor
        searchBar.backgroundColor = systemBackground
    }

    //MARK: - Table Header

    static func styleLabel(asTableHeader v: UILabel) {
        v.textColor = Style.secondaryLabelColor
        v.backgroundColor = Style.systemGroupedBackground
        // Create the small-caps font and scale it for Dynamic Type
        let baseFont = UIFont.systemFont(ofSize: calloutSize, weight: .light).withSmallCaps
        v.font = UIFontMetrics(forTextStyle: .callout).scaledFont(for: baseFont)
        v.adjustsFontForContentSizeCategory = true
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
}
