//
//  ShowCardViewController.swift
//
//  Copyright (C) 2018 Erik Cox
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
import ZXingObjC

class ShowCardViewController: UIViewController {
    
    @IBOutlet weak var barcodeImage: UIImageView!
    @IBOutlet weak var barcodeWarningLabel: UILabel!
    @IBOutlet weak var barcodeLabel: UILabel!
    @IBOutlet weak var splashImage: UIImageView!

    let imageWidth: Int32 = 400
    let imageHeight: Int32 = 200
    var savedBrightness: CGFloat = 0.5

    //MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        savedBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = 1.0
     }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIScreen.main.brightness = savedBrightness
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setupSplash()
    }
    
    //MARK: - Functions
    
    func setupViews() {
        setupSplash()
        setupBarcode()
        setupBarcodeTapActions()
        self.setupHomeButton()
    }
    
    func setupSplash() {        
        // hide splash in landscape so it doesn't obscure the barcode
        splashImage.isHidden = UIDevice.current.orientation.isLandscape
    }

    func setupBarcodeTapActions() {
        barcodeImage.isUserInteractionEnabled = true
        barcodeImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(barcodeTapped)))
        barcodeLabel.isUserInteractionEnabled = true
        barcodeLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(barcodeTapped)))
    }

    @objc private func barcodeTapped(_ recognizer: UITapGestureRecognizer) {
        guard let barcode = App.account?.barcode else { return }
        UIPasteboard.general.string = barcode
        self.navigationController?.view.makeToast("Barcode copied to clipboard")

    }

    func setupBarcode() {
        guard let account = App.account else { return }
        guard let barcode = account.barcode,
            let m = BarcodeUtils.tryEncode(barcode, width: imageWidth, height: imageHeight, formats: [.Codabar, .Code39]),
            m.width > 0 && m.height > 0,
            let cgimage = ZXImage(matrix: m).cgimage else
        {
            barcodeLabel.text = "Invalid barcode: \(account.barcode ?? "empty")"
            barcodeImage.image = loadAssetImage(named: "invalid_barcode")
            return
        }
        barcodeLabel.text = BarcodeUtils.displayLabel(barcode, format: App.config.barcodeFormat)
        barcodeImage.image = UIImage(cgImage: cgimage)
        if let dateStr = account.expireDateLabel {
            barcodeWarningLabel.text = "Expires: \(dateStr)"
            barcodeWarningLabel.isHidden = false
        }
    }
}
