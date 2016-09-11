//
//  DrawViewController.swift
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
import Toast_Swift

class DrawViewController: JotViewController {

    //drawing variables
    let drawButton: UIButton = UIButton()
    let saveButton: UIButton = UIButton()
    let closeButton: UIButton = UIButton(type: .Custom)
    let undoButton: UIButton = UIButton()
    let sendButton: UIButton = UIButton()
    let colorSlider: ColorSlider! = ColorSlider()
    let colorButton: UIButton = UIButton(type: .Custom)
    let strokeButton: UIButton = UIButton(type: .Custom)
    let strokeImages: [UIImage] = [
        UIImage(named: "stroke-1")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate),
        UIImage(named: "stroke-2")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate),
        UIImage(named: "stroke-3")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate),
        UIImage(named: "stroke-4")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate),
    ]

    var strokeIndex = 1

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

        self.requestManager = RequestManager()
        self.updatePictureBlock = {(doodle: Doodle) -> Void in
            self.bufferedDoodles.append(doodle)
        }

        requestManager!.getDoodles(self.updatePictureBlock, semaphore: self.gettingDoodlesSemaphore)
        dispatch_semaphore_wait(self.gettingDoodlesSemaphore, DISPATCH_TIME_FOREVER)
        self.imageView?.image = self.bufferedDoodles[1].getImage()
        
        //set up close button
        closeButton.hidden = true
        if let image = UIImage(named: "close") {
            closeButton.setImage(image, forState: .Normal)
        }

        closeButton.addTarget(self, action: #selector(onClose), forControlEvents: .TouchUpInside)
        self.view.addSubview(closeButton)

        closeButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(8)
            make.left.equalTo(self.view).offset(0)
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
        strokeButton.setImage(strokeImages[1], forState: .Normal)
        strokeButton.addTarget(self, action: #selector(onStrokeChange), forControlEvents: .TouchUpInside)
        self.view.addSubview(strokeButton)

        strokeButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(7)
            make.right.equalTo(self.view).offset(-60)
        }

        //set up color buttons
        colorButton.hidden = true
        if let image = UIImage(named: "spray-can") {
            colorButton.setImage(image, forState: .Normal)
        }
        colorButton.backgroundColor = UIColor.clearColor()
        colorButton.addTarget(self, action: #selector(onColor), forControlEvents: .TouchUpInside)
        colorButton.layer.cornerRadius = 5
        colorButton.layer.borderWidth = 2
        colorButton.layer.borderColor = UIColor.whiteColor().CGColor

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
        //intentionally made it 5 so its nil and cannot be interacted with
        self.state = JotViewState.init(rawValue: 5)!
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
        imageView!.image = nil
        colorButton.backgroundColor = UIColor.redColor()
        strokeButton.imageView?.tintColor = UIColor.redColor()
        self.state = JotViewState.Drawing
        self.toggleDrawing()
    }

    @IBAction func onSave(sender: AnyObject) {
        /*let photoImage: UIImage!
        var camera: UIImage!

        if let parentVC = self.parentViewController {
            if let mainVC = parentVC as? MainViewController {
                camera = mainVC.takeScreenshot()
            }
        }

        photoImage = camera*/

        let layer = UIApplication.sharedApplication().keyWindow!.layer
        let scale = UIScreen.mainScreen().scale

        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
            layer.renderInContext(UIGraphicsGetCurrentContext()!)
            let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        //UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
        //    let areaSize = CGRect(x: 0, y: 0, width: layer.frame.size.width, height: layer.frame.size.height)
            //photoImage.drawInRect(areaSize)
            //screenshot.drawInRect(areaSize)
            //let combinedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        //UIGraphicsEndImageContext()

        UIImageWriteToSavedPhotosAlbum(screenshot, nil, nil, nil)
        self.view.makeToast("Screenshot saved!")
    }

    @IBAction func onSend(sender: AnyObject) {
        let scale = UIScreen.mainScreen().scale
        let doodle: UIImage = self.renderImageWithScale(scale)
        self.requestManager!.tagDoodle(doodle)
        colorSlider.hidden = true
        colorButton.backgroundColor = UIColor.clearColor()
        self.state = JotViewState.Default
        self.onClose(NSNull)
    }

    @IBAction func onClose(sender: AnyObject) {
        self.clearAll()
        colorSlider.hidden = true
        colorButton.backgroundColor = UIColor.clearColor()
        self.state = JotViewState.Default
        self.toggleDrawing()
    }

    @IBAction func onUndo(sender: AnyObject) {
        self.undo()
    }

    @IBAction func onStrokeChange(sender: AnyObject) {
        self.drawingStrokeWidth = self.drawingStrokeWidth + 5.0
        strokeIndex += 1
        if(self.drawingStrokeWidth > 20.0) {
            self.drawingStrokeWidth = 5.0
        }
        if(strokeIndex > 3) {
            strokeIndex = 0
        }
        strokeButton.setImage(strokeImages[strokeIndex], forState: .Normal)

    }

    @IBAction func onColor(sender: AnyObject) {
        colorSlider.hidden = !(colorSlider.hidden)
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
        strokeButton.imageView?.tintColor = slider.color
        colorButton.backgroundColor = colorSlider.color
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
