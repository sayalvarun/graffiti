//
//  MainViewController.swift
//  graffiti
//
//  Created by Philippe Kimura-Thollander on 9/10/16.
//  Copyright © 2016 Philippe Kimura-Thollander. All rights reserved.
//

import UIKit
import Masonry
import jot

class MainViewController: UIViewController, JotViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let drawViewController = DrawViewController()
        let _ = drawViewController.view
        //print(drawViewController.saveButton)
        
        drawViewController.delegate = self
        self.addChildViewController(drawViewController)
        self.view.addSubview(drawViewController.view)
        drawViewController.didMoveToParentViewController(self)
        drawViewController.view.frame = self.view.frame
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
