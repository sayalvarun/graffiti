//
//  Doodle.swift
//  graffiti
//
//  Created by Varun Sayal on 9/10/16.
//  Copyright © 2016 Philippe Kimura-Thollander. All rights reserved.
//

import UIKit

class Doodle: NSObject {

    var id: Int32 = 0
    var image: UIImage!
    
    init(id: Int32, image: UIImage?) {
        
        if(id<0)
        {
            print("Error: Negative Doodle ID passed")
            return
        }
        
        self.id = id
        
        self.image = image!
        
    }
    
    func getID() -> Int32{
        return self.id
    }
    
    func getImage() -> UIImage{
        return self.image
    }
    
}
