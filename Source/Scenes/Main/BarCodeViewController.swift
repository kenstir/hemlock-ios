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
        barCodeImage.image = Barcode.fromString(string: "whatevs")
//        NSError *error = nil;
//        ZXMultiFormatWriter BCwriter = [ZXMultiFormatWriter writer];
//        ZXBitMatrix* result = [writer encode:@"A string to encode"
//            format:kBarcodeFormatQRCode
//            width:500
//            height:500
//            error:&error];
//        if (result) {
//            CGImageRef image = CGImageRetain([[ZXImage imageWithMatrix:result] cgimage]);
//
//            // This CGImageRef image can be placed in a UIImage, NSImage, or written to a file.
//
//            CGImageRelease(image);
//        } else {
//            NSString *errorMessage = [error localizedDescription];
//        }
//
    }
}

