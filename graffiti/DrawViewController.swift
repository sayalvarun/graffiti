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

    var requestManager: RequestManager?
    var updatePictureBlock:(image: UIImage)->Void = { arg in }
    var imageView : UIImageView!
    var colorSlider: ColorSlider! = ColorSlider()
    var colorButton: UIButton = UIButton(type: .Custom)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        self.imageView = UIImageView(frame: CGRect(x: 75, y: 150, width: 200, height: 400))
        imageView!.frame = self.view.frame
        
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
            make.right.equalTo(self.view).offset(-120)
        }
        
        //set up stroke button
        let strokeButton = UIButton()
        strokeButton.setTitle("Stroke", forState: .Normal)
        strokeButton.addTarget(self, action: #selector(onStrokeChange), forControlEvents: .TouchUpInside)
        self.view.addSubview(strokeButton)
        
        strokeButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(20)
            make.right.equalTo(self.view).offset(-60)
        }
        
        //set up color buttons
        if let image = UIImage(named: "spray-can") {
            print(image)
            colorButton.setImage(image, forState: .Normal)
        }
        colorButton.backgroundColor = UIColor.clearColor()
        colorButton.layer.cornerRadius = 5
        colorButton.layer.borderWidth = 2
        colorButton.layer.borderColor = UIColor.whiteColor().CGColor

        
        colorButton.addTarget(self, action: #selector(onColor), forControlEvents: .TouchUpInside)
        self.view.addSubview(colorButton)
        
    
        colorButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(20)
            make.right.equalTo(self.view).offset(-20)
        }
        
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
        
        
        //set up save buttons
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
    
    @IBAction func onClose(sender: AnyObject) {
        self.clearAll()
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
