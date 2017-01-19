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
    let drawButton: UIButton = UIButton(type: .custom)
    let saveButton: UIButton = UIButton(type: .custom)
    let textButton: UIButton = UIButton(type: .custom)
    let closeButton: UIButton = UIButton(type: .custom)
    let undoButton: UIButton = UIButton(type: .custom)
    let sendButton: UIButton = UIButton(type: .custom)
    let colorSlider: ColorSlider! = ColorSlider()
    let voteButton: UIButton = UIButton(type: .custom)
    let colorButton: UIButton = UIButton(type: .custom)
    let strokeButton: UIButton = UIButton(type: .custom)
    let strokeImages: [UIImage] = [
        UIImage(named: "stroke-1")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate),
        UIImage(named: "stroke-2")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate),
        UIImage(named: "stroke-3")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate),
        UIImage(named: "stroke-4")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate),
    ]
    var strokeIndex = 1

    //graffiti variables
    var requestManager: RequestManager?
    var updatePictureBlock:(_ doodle: Doodle)->Void = { arg in }
    var imageView : UIImageView =  UIImageView(frame: CGRect(x: 75, y: 150, width: 200, height: 400))
    var currentDoodleID : Int32 = -1 // Stores the id of the doodle on the screen if any
    var bufferedDoodles : [Doodle] = []
    var gettingDoodlesSemaphore : DispatchSemaphore = DispatchSemaphore(value: 0)
    let kSemaphoreWaitTime : Int64 = 15 // Wait for 15 seconds for the semaphore
    
    var timer = Timer()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        
        //set up imageview
        imageView.frame = self.view.frame
        
        //let singleTap = UITapGestureRecognizer(target: self, action: #selector(upVote))
        //singleTap.numberOfTapsRequired = 1
        //imageView.userInteractionEnabled = true
        //imageView.addGestureRecognizer(singleTap)
        
        self.view.addSubview(imageView)

        //set up close button
        closeButton.isHidden = true
        if let image = UIImage(named: "close") {
            closeButton.setImage(image, for: UIControlState())
        }

        closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)
        self.view.addSubview(closeButton)

        closeButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(8)
            make.left.equalTo(self.view).offset(0)
        }

        //set up undo button
        undoButton.isHidden = true
        if let image = UIImage(named: "undo") {
            undoButton.setImage(image, for: UIControlState())
        }
        undoButton.addTarget(self, action: #selector(onUndo), for: .touchUpInside)
        self.view.addSubview(undoButton)

        undoButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(5)
            make.right.equalTo(self.view).offset(-145)
        }
        
        //set up text button
        textButton.isHidden = true
        if let image = UIImage(named: "text") {
            textButton.setImage(image, for: UIControlState())
        }
        textButton.addTarget(self, action: #selector(onText), for: .touchUpInside)
        self.view.addSubview(textButton)
        
        textButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(8)
            make.right.equalTo(self.view).offset(-100)
        }
        
        //set up text button
        if let image = UIImage(named: "vote") {
            voteButton.setImage(image, for: UIControlState())
        }
        voteButton.isHidden = true
        voteButton.addTarget(self, action: #selector(upVote), for: .touchUpInside)
        self.view.addSubview(voteButton)
        
        voteButton.snp_makeConstraints { (make) -> Void in
            make.bottom.equalTo(self.view).offset(-5)
            make.left.equalTo(self.view).offset(10)
        }
        
        //set up stroke button
        strokeButton.isHidden = true
        strokeButton.setImage(strokeImages[1], for: UIControlState())
        strokeButton.addTarget(self, action: #selector(onStrokeChange), for: .touchUpInside)
        self.view.addSubview(strokeButton)

        strokeButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(7)
            make.right.equalTo(self.view).offset(-60)
        }

        //set up color buttons
        colorButton.isHidden = true
        if let image = UIImage(named: "spray-can") {
            colorButton.setImage(image, for: UIControlState())
        }
        colorButton.backgroundColor = UIColor.clear
        colorButton.addTarget(self, action: #selector(onColor), for: .touchUpInside)
        colorButton.layer.cornerRadius = 5
        colorButton.layer.borderWidth = 2
        colorButton.layer.borderColor = UIColor.white.cgColor

        self.view.addSubview(colorButton)

        colorButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(20)
            make.right.equalTo(self.view).offset(-20)
        }


        //set up color slider
        let colorSliderWidth = CGFloat(25)
        let colorSliderHeight = CGFloat(150)
        let colorSliderPadding = CGFloat(15)

        colorSlider.frame = CGRect(x: view.bounds.width - colorSliderWidth - colorSliderPadding - 5, y: 50 + colorSliderPadding, width: colorSliderWidth, height: colorSliderHeight)
        colorSlider.isHidden = true
        colorSlider.addTarget(self, action: #selector(changedColor), for: .valueChanged)
        colorSlider.addTarget(self, action: #selector(changedColor), for: .touchUpInside)

        colorSlider.borderWidth = 2.0
        colorSlider.borderColor = UIColor.white
        self.view.addSubview(colorSlider)

        //set up draw buttons
        if let image = UIImage(named: "can-menu") {
            drawButton.setImage(image, for: UIControlState())
        }

        drawButton.addTarget(self, action: #selector(onDraw), for: .touchUpInside)
        self.view.addSubview(drawButton)

        drawButton.snp_makeConstraints { (make) -> Void in
            make.bottom.equalTo(self.view).offset(0)
            make.centerX.equalTo(self.view)
            //make.bottom.equalTo()(self.view).with().offset()(-4.0)
        }

        //set up send button
        sendButton.isHidden = true
        if let image = UIImage(named: "tag") {
            sendButton.setImage(image, for: UIControlState())
        }
        sendButton.addTarget(self, action: #selector(onSend), for: .touchUpInside)
        self.view.addSubview(sendButton)
        sendButton.snp_makeConstraints { (make) -> Void in
            make.bottom.equalTo(self.view).offset(10)
            make.right.equalTo(self.view).offset(10)
        }

        //set up save button
        saveButton.isHidden = true
        if let image = UIImage(named: "download") {
            saveButton.setImage(image, for: UIControlState())
        }

        saveButton.addTarget(self, action: #selector(onSave), for: .touchUpInside)
        self.view.addSubview(saveButton)

        saveButton.snp_makeConstraints { (make) -> Void in
            make.bottom.equalTo(self.view).offset(-10)
            make.left.equalTo(self.view).offset(5)
        }

        //set state of drawing view
        //intentionally made it 5 so its nil and cannot be interacted with
        self.state = JotViewState.init(rawValue: 5)!
        self.drawingColor = UIColor.red
        self.requestManager = RequestManager()
        self.updatePictureBlock = {(doodle: Doodle) -> Void in
            self.bufferedDoodles.append(doodle)
        }

        //requestDoodles()
        self.timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(DrawViewController.requestDoodles), userInfo: nil, repeats: true)
    }

    /* Makes an async request to the server asking for all nearby doodles and adds them to the
    *  bufferedDoodles. Needs to be called again when we exhaust all the doodles
    */
    func requestDoodles() {
        self.bufferedDoodles.removeAll()
        requestManager!.getDoodles(self.updatePictureBlock, semaphore: self.gettingDoodlesSemaphore)
        self.gettingDoodlesSemaphore.wait(timeout: DispatchTime.distantFuture)
        print("Number of doodles = \(self.bufferedDoodles.count)")
        if(self.state == JotViewState.default || self.state.rawValue == 5){
            if(self.bufferedDoodles.count >= 1) // We are in a state of viewing
            {
                voteButton.isHidden = false
                self.imageView.image = self.bufferedDoodles[0].getImage()
                self.currentDoodleID = self.bufferedDoodles[0].getID()
            }
            else {
                self.imageView.image = nil
                voteButton.isHidden = true
            }
        }
    }

    @IBAction func onDraw(_ sender: AnyObject) {
        colorButton.backgroundColor = UIColor.red
        strokeButton.imageView?.tintColor = UIColor.red
        imageView.image = nil
        voteButton.isHidden = true
        self.state = JotViewState.drawing
        self.toggleDrawing()
        print(self.state.rawValue)
    }
    
    @IBAction func onSave(_ sender: AnyObject) {
        /*let photoImage: UIImage!
        var camera: UIImage!

        if let parentVC = self.parentViewController {
            if let mainVC = parentVC as? MainViewController {
                camera = mainVC.takeScreenshot()
            }
        }

        photoImage = camera*/

        let layer = UIApplication.shared.keyWindow!.layer
        let scale = UIScreen.main.scale

        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
            layer.render(in: UIGraphicsGetCurrentContext()!)
            let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        //UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
        //    let areaSize = CGRect(x: 0, y: 0, width: layer.frame.size.width, height: layer.frame.size.height)
            //photoImage.drawInRect(areaSize)
            //screenshot.drawInRect(areaSize)
            //let combinedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        //UIGraphicsEndImageContext()

        UIImageWriteToSavedPhotosAlbum(screenshot!, nil, nil, nil)
        self.view.makeToast("Screenshot saved!")
    }

    @IBAction func onSend(_ sender: AnyObject) {
        let scale = UIScreen.main.scale
        let doodle: UIImage = self.renderImage(withScale: scale)
        self.requestManager!.tagDoodle(doodle)
        colorSlider.isHidden = true
        colorButton.backgroundColor = UIColor.clear
        self.view.makeToast("Tag created!")
        self.state = JotViewState.default
        self.onClose(NSNull.self)
    }
    
    @IBAction func onText(_ sender: AnyObject) {
        self.state = JotViewState.editingText
    }

    @IBAction func onClose(_ sender: AnyObject) {
        self.clearAll()
        colorSlider.isHidden = true
        colorButton.backgroundColor = UIColor.clear
        self.state = JotViewState.default
        self.toggleDrawing()
    }

    func upVote() {
        if(currentDoodleID > 0) {
            requestManager!.vote(currentDoodleID, up: true)
            self.view.makeToast("Doodle upvoted!")
        }
    }
    
    @IBAction func onUndo(_ sender: AnyObject) {
        self.undo()
    }

    @IBAction func onStrokeChange(_ sender: AnyObject) {
        self.drawingStrokeWidth = self.drawingStrokeWidth + 5.0
        strokeIndex += 1
        if(self.drawingStrokeWidth > 20.0) {
            self.drawingStrokeWidth = 5.0
        }
        if(strokeIndex > 3) {
            strokeIndex = 0
        }
        strokeButton.setImage(strokeImages[strokeIndex], for: UIControlState())

    }

    @IBAction func onColor(_ sender: AnyObject) {
        colorSlider.isHidden = !(colorSlider.isHidden)
        self.state = JotViewState.drawing
    }

    func toggleDrawing() {
        drawButton.isHidden = !(drawButton.isHidden)
        saveButton.isHidden = !(saveButton.isHidden)
        strokeButton.isHidden = !(strokeButton.isHidden)
        closeButton.isHidden = !(closeButton.isHidden)
        undoButton.isHidden = !(undoButton.isHidden)
        colorButton.isHidden = !(colorButton.isHidden)
        sendButton.isHidden = !(sendButton.isHidden)
        textButton.isHidden = !(textButton.isHidden)
    }


    func changedColor(_ slider: ColorSlider) {
        self.drawingColor = slider.color
        strokeButton.imageView?.tintColor = slider.color
        colorButton.backgroundColor = colorSlider.color
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
