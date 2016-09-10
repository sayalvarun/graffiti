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
    
    var jotController: JotViewController = JotViewController()

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
    }

    @IBAction func onSave(sender: AnyObject) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

