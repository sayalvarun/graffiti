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



class DrawViewController: UIViewController, JotViewControllerDelegate {
    
    @IBOutlet weak var ImageView: UIImageView!
    
    var jotController: JotViewController = JotViewController()
    var requestManager: RequestManager?
    var updatePictureBlock:(image: UIImage)->Void = { arg in }
    

    @IBOutlet weak var saveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        jotController.delegate = self
        jotController.state = JotViewState.Drawing
        jotController.drawingColor = UIColor.blackColor()
        self.addChildViewController(jotController)
        self.view.addSubview(jotController.view)
        jotController.didMoveToParentViewController(self)
        jotController.view.mas_makeConstraints { (make: MASConstraintMaker!) in
            make.edges.equalTo()
        }
        self.requestManager = RequestManager()
        self.updatePictureBlock = {(image: UIImage) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                self.ImageView.image = image
            })
        }
        
        requestManager!.getDoodle(self.updatePictureBlock)
        
    }

    @IBAction func onSave(sender: AnyObject) {
        let image = UIImage(named: "fist")
        if let data = UIImagePNGRepresentation(image!)
        {
            self.requestManager!.tagDoodle(data)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

