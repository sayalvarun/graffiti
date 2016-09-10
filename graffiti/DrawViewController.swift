//
//  ViewController.swift
//  graffiti
//
//  Created by Philippe Kimura-Thollander on 9/9/16.
//  Copyright © 2016 Philippe Kimura-Thollander. All rights reserved.
//

import UIKit
import Masonry
import jot
import SnapKit

class DrawViewController: JotViewController {

    var requestManager: RequestManager?
    var updatePictureBlock:(image: UIImage)->Void = { arg in }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let button = UIButton()
        button.setTitle("Save", forState: .Normal)
        button.addTarget(self, action: #selector(onSave), forControlEvents: .TouchUpInside)
        self.view.addSubview(button)

        button.snp_makeConstraints { (make) -> Void in
            make.bottom.equalTo(self.view).offset(-20)
            make.right.equalTo(self.view).offset(-20)
            //make.bottom.equalTo()(self.view).with().offset()(-4.0)
        }


        self.state = JotViewState.Drawing
        self.drawingColor = UIColor.redColor()

        self.requestManager = RequestManager()
//        self.updatePictureBlock = {(image: UIImage) -> Void in
//            dispatch_async(dispatch_get_main_queue(), {
//                self.ImageView.image = image
//            })
//        }

        requestManager!.getDoodle(self.updatePictureBlock)
    }

    @IBAction func onSave(sender: AnyObject) {
        let doodle: UIImage = self.renderImageWithScale(2.0)
        if let data = UIImagePNGRepresentation(doodle)
        {
            self.requestManager!.tagDoodle(data)
        }
        UIImageWriteToSavedPhotosAlbum(doodle, nil, nil, nil)
        self.clearAll()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
