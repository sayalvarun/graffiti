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

class DrawViewController: JotViewController {
    
    var requestManager: RequestManager?
    var updatePictureBlock:(image: UIImage)->Void = { arg in }
    var imageView : UIImageView?
    
    @IBOutlet weak var test: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let button = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
        button.setTitle("Save", forState: .Normal)
        button.addTarget(self, action: #selector(onSave), forControlEvents: .TouchUpInside)
        
        self.view.addSubview(button)
        
        self.imageView = UIImageView(frame: CGRect(x: 75, y: 150, width: 200, height: 400))
        
        self.view.addSubview(self.imageView!)
        
        self.state = JotViewState.Drawing
        self.drawingColor = UIColor.redColor()
        
        self.requestManager = RequestManager()
        self.updatePictureBlock = {(image: UIImage) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                self.imageView!.image = image
            })
        }
        
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

