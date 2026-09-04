//
//  Copyright (c) 2026 Kenneth H. Cox
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
import PINRemoteImage

/// Full-screen image inside a ScrollView to allow zooming and panning. Tapping the image will dismiss the view.
class FullScreenImageViewController: UIViewController, UIScrollViewDelegate {

    var imageURL: String?

    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        let screenBounds = UIScreen.main.bounds
        scroll.frame = screenBounds
        scroll.backgroundColor = .black
        scroll.minimumZoomScale = 1.0
        scroll.maximumZoomScale = 4.0
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        return scroll
    }()

    private let imageView: UIImageView = {
        let image = UIImageView()
        let screenBounds = UIScreen.main.bounds
        image.frame = screenBounds
        image.contentMode = .scaleAspectFit
        image.isUserInteractionEnabled = true
        return image
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        scrollView.delegate = self

        // Assemble views
        scrollView.addSubview(imageView)
        view.addSubview(scrollView)

        // Async load the image
        if let imageURL = imageURL,
           let url = URL(string: imageURL) {
            imageView.pin_setImage(from: url)
        }

        // Add a tap gesture to dismiss
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss)))
    }

    // Tell the ScrollView which specific subview to zoom
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    // Keep the image centered on the screen while zooming
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let subView = scrollView.subviews[0]
        let offsetX = max((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5, 0.0)
        let offsetY = max((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5, 0.0)
        subView.center = CGPoint(
            x: scrollView.contentSize.width * 0.5 + offsetX,
            y: scrollView.contentSize.height * 0.5 + offsetY)
    }

    @objc private func handleDismiss() {
        dismiss(animated: true, completion: nil)
    }
}
