//
//  PopVC.swift
//  PixelCity
//
//  Created by Perfect on 2017/12/5.
//  Copyright © 2017年 Alex. All rights reserved.
//

import UIKit

class PopVC: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var popImageView: UIImageView!
    private var popImage = UIImage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        popImageView.image = popImage
        addDoubleTap()
    }

    func initData(forImage image: UIImage) {
        popImage = image
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(screenWasTapped))
        doubleTap.delegate = self
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
    }
    
    @objc func screenWasTapped() {
        dismiss(animated: true, completion: nil)
    }
}
