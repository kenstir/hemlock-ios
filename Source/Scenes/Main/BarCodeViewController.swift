//
//  BarCodeViewController.swift
//  Hemlock
//
//  Created by Erik Cox on 11/9/18.
//  Copyright © 2018 Ken Cox. All rights reserved.
//

import Foundation
import UIKit
import ZXingObjC

class BarCodeViewController: UIViewController {

    class Barcode {
        
        class func fromString(string : String) -> UIImage? {
            
            let data = string.data(using: .ascii)
            let filter = CIFilter(name: "CICode128BarcodeGenerator")
            filter?.setValue(data, forKey: "inputMessage")
            
            return UIImage(ciImage: (filter?.outputImage)!)
        }
        
    }
    
    @IBOutlet weak var barCodeImage: UIImageView!
    //MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    func setupViews() {
        let writer = ZXMultiFormatWriter()
        if let matrix = try? writer.encode("1234567", format: kBarcodeFormatCodabar, width: 500, height: 200) {
            debugPrint(matrix)
            if let cgimage = ZXImage(matrix: matrix).cgimage {
                barCodeImage.image = UIImage(cgImage: cgimage)
            }
        }
    }
}

