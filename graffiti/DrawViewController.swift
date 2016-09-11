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
import ColorSlider

class DrawViewController: JotViewController {

    //drawing variables
    let drawButton: UIButton = UIButton()
    let saveButton: UIButton = UIButton()
    let closeButton: UIButton = UIButton()
    let strokeButton: UIButton = UIButton()
    let undoButton: UIButton = UIButton()
    let sendButton: UIButton = UIButton()
    let colorSlider: ColorSlider! = ColorSlider()
    let colorButton: UIButton = UIButton(type: .Custom)
    
    //graffiti variables
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
        imageView!.frame = self.view.frame
        
        self.view.addSubview(self.imageView!)
        
        //set up close button
        closeButton.hidden = true
        closeButton.setTitle("Close", forState: .Normal)
        closeButton.addTarget(self, action: #selector(onClose), forControlEvents: .TouchUpInside)
        self.view.addSubview(closeButton)
        
        closeButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(20)
            make.left.equalTo(self.view).offset(20)
        }
        
        //set up undo button
        undoButton.hidden = true
        undoButton.setTitle("Undo", forState: .Normal)
        undoButton.addTarget(self, action: #selector(onUndo), forControlEvents: .TouchUpInside)
        self.view.addSubview(undoButton)
        
        undoButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(20)
            make.right.equalTo(self.view).offset(-120)
        }
        
        //set up stroke button
        strokeButton.hidden = true
        strokeButton.setTitle("Stroke", forState: .Normal)
        strokeButton.addTarget(self, action: #selector(onStrokeChange), forControlEvents: .TouchUpInside)
        self.view.addSubview(strokeButton)
        
        strokeButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(20)
            make.right.equalTo(self.view).offset(-60)
        }
        
        //set up color buttons
        colorButton.hidden = true
        if let image = UIImage(named: "spray-can") {
            print(image)
            colorButton.setImage(image, forState: .Normal)
        }
        colorButton.backgroundColor = UIColor.clearColor()
        colorButton.addTarget(self, action: #selector(onColor), forControlEvents: .TouchUpInside)
        self.view.addSubview(colorButton)
    
        colorButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(20)
            make.right.equalTo(self.view).offset(-20)
        }
        
        //set up color slider
        let colorSliderWidth = CGFloat(12)
        let colorSliderHeight = CGFloat(150)
        let colorSliderPadding = CGFloat(15)
        
        colorSlider.frame = CGRectMake(view.bounds.width - colorSliderWidth - colorSliderPadding - 5, 40 + colorSliderPadding, colorSliderWidth, colorSliderHeight)
        colorSlider.hidden = true
        colorSlider.addTarget(self, action: #selector(changedColor), forControlEvents: .ValueChanged)
        colorSlider.addTarget(self, action: #selector(changedColor), forControlEvents: .TouchUpInside)

        colorSlider.borderWidth = 2.0
        colorSlider.borderColor = UIColor.whiteColor()
        self.view.addSubview(colorSlider)
        
        //set up draw buttons
        drawButton.setTitle("Draw", forState: .Normal)
        drawButton.addTarget(self, action: #selector(onDraw), forControlEvents: .TouchUpInside)
        self.view.addSubview(drawButton)

        drawButton.snp_makeConstraints { (make) -> Void in
            make.bottom.equalTo(self.view).offset(-20)
            make.centerX.equalTo(self.view)
            //make.bottom.equalTo()(self.view).with().offset()(-4.0)
        }
        
        //set up send button
        sendButton.hidden = true
        sendButton.setTitle("Send", forState: .Normal)
        sendButton.addTarget(self, action: #selector(onSend), forControlEvents: .TouchUpInside)
        self.view.addSubview(sendButton)
        sendButton.snp_makeConstraints { (make) -> Void in
            make.bottom.equalTo(self.view).offset(-20)
            make.right.equalTo(self.view).offset(-20)
        }
        
        //set up save button
        saveButton.hidden = true
        saveButton.setTitle("Save", forState: .Normal)
        saveButton.addTarget(self, action: #selector(onSave), forControlEvents: .TouchUpInside)
        self.view.addSubview(saveButton)
        
        saveButton.snp_makeConstraints { (make) -> Void in
            make.bottom.equalTo(self.view).offset(-20)
            make.left.equalTo(self.view).offset(20)
        }

        //set state of drawing view
        self.state = JotViewState.Default
        self.drawingColor = UIColor.redColor()

        self.requestManager = RequestManager()
        self.updatePictureBlock = {(doodle: Doodle) -> Void in
            self.bufferedDoodles.append(doodle)
        }
        
        requestDoodles()
    }
    
    /* Makes an async request to the server asking for all nearby doodles and adds them to the
    *  bufferedDoodles. Needs to be called again when we exhaust all the doodles
    */
    func requestDoodles() {
        requestManager!.getDoodles(self.updatePictureBlock, semaphore: self.gettingDoodlesSemaphore)
        dispatch_semaphore_wait(self.gettingDoodlesSemaphore, DISPATCH_TIME_FOREVER)
        if(self.bufferedDoodles.count >= 1)
        {
            self.imageView?.image = self.bufferedDoodles[0].getImage()
        }
    }

    @IBAction func onDraw(sender: AnyObject) {
        self.imageView!.image = nil
        self.state = JotViewState.Drawing
        self.toggleDrawing()
    }
    
    @IBAction func onSave(sender: AnyObject) {
        let layer = UIApplication.sharedApplication().keyWindow!.layer
        let scale = UIScreen.mainScreen().scale
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
        
        layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        UIImageWriteToSavedPhotosAlbum(screenshot, nil, nil, nil)
    }
    
    @IBAction func onSend(sender: AnyObject) {
        let scale = UIScreen.mainScreen().scale
        let doodle: UIImage = self.renderImageWithScale(scale)
        self.requestManager!.tagDoodle(doodle)
        self.state = JotViewState.Default
        self.onClose(NSNull)
    }
    
    @IBAction func onClose(sender: AnyObject) {
        self.clearAll()
        colorSlider.hidden = true
        self.state = JotViewState.Default
        self.toggleDrawing()
    }
    
    @IBAction func onUndo(sender: AnyObject) {
        self.undo()
    }
    
    @IBAction func onStrokeChange(sender: AnyObject) {
        self.drawingStrokeWidth = self.drawingStrokeWidth + 5.0
        if(self.drawingStrokeWidth > 20.0) {
            self.drawingStrokeWidth = 5.0
        }
    }
    
    @IBAction func onColor(sender: AnyObject) {
        colorSlider.hidden = !(colorSlider.hidden)
        if colorButton.layer.cornerRadius == 0 {
            colorButton.layer.cornerRadius = 5
            colorButton.layer.borderWidth = 2
            colorButton.layer.borderColor = UIColor.whiteColor().CGColor
        }
        else {
            colorButton.layer.cornerRadius = 0
            colorButton.layer.borderWidth = 0
            colorButton.backgroundColor = UIColor.clearColor()
        }
    }
    
    func toggleDrawing() {
        drawButton.hidden = !(drawButton.hidden)
        saveButton.hidden = !(saveButton.hidden)
        strokeButton.hidden = !(strokeButton.hidden)
        closeButton.hidden = !(closeButton.hidden)
        undoButton.hidden = !(undoButton.hidden)
        colorButton.hidden = !(colorButton.hidden)
        sendButton.hidden = !(sendButton.hidden)
    }

    
    func changedColor(slider: ColorSlider) {
        self.drawingColor = slider.color
        colorButton.backgroundColor = colorSlider.color
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
