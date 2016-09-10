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
    var updatePictureBlock:(doodle: Doodle)->Void = { arg in }
    var imageView : UIImageView?
    var currentDoodleID : Int32 = 0 // Stores the id of the doodle on the screen if any
    var bufferedDoodles : [Doodle] = []
    var gettingDoodlesSemaphore : dispatch_semaphore_t = dispatch_semaphore_create(0)
    let kSemaphoreWaitTime : Int64 = 15 // Wait for 15 seconds for the semaphore
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.imageView = UIImageView(frame: CGRect(x: 75, y: 150, width: 200, height: 400))
        
        self.view.addSubview(self.imageView!)
        
        //set up close button
        let closeButton = UIButton()
        closeButton.setTitle("Close", forState: .Normal)
        closeButton.addTarget(self, action: #selector(onClose), forControlEvents: .TouchUpInside)
        self.view.addSubview(closeButton)
        
        closeButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(20)
            make.left.equalTo(self.view).offset(20)
        }
        
        //set up undo button
        let undoButton = UIButton()
        undoButton.setTitle("Undo", forState: .Normal)
        undoButton.addTarget(self, action: #selector(onUndo), forControlEvents: .TouchUpInside)
        self.view.addSubview(undoButton)
        
        undoButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(20)
            make.right.equalTo(self.view).offset(-20)
        }
        
        //set up save butoon
        let saveButton = UIButton()
        saveButton.setTitle("Save", forState: .Normal)
        saveButton.addTarget(self, action: #selector(onSave), forControlEvents: .TouchUpInside)
        self.view.addSubview(saveButton)

        saveButton.snp_makeConstraints { (make) -> Void in
            make.bottom.equalTo(self.view).offset(-20)
            make.centerX.equalTo(self.view)
            //make.bottom.equalTo()(self.view).with().offset()(-4.0)
        }

        //set state of drawing view
        self.state = JotViewState.Drawing
        self.drawingColor = UIColor.redColor()

        self.requestManager = RequestManager()
        self.updatePictureBlock = {(doodle: Doodle) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                self.bufferedDoodles.append(doodle)
            })
        }
        
        requestDoodles()
    }
    
    /* Makes an async request to the server asking for all nearby doodles and adds them to the
    *  bufferedDoodles. Needs to be called again when we exhaust all the doodles
    */
    func requestDoodles() {
        requestManager!.getDoodle(self.updatePictureBlock, semaphore: self.gettingDoodlesSemaphore)
        dispatch_semaphore_wait(self.gettingDoodlesSemaphore, dispatch_time(DISPATCH_TIME_NOW, self.kSemaphoreWaitTime))
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
    
    @IBAction func onClose(sender: AnyObject) {
        self.clearAll()
    }
    
    @IBAction func onUndo(sender: AnyObject) {
        self.undo()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
