//
//  RequestManager.swift
//  graffiti
//
//  Created by Varun Sayal on 9/10/16.
//  Copyright © 2016 ___varun___. All rights reserved.
//

import UIKit

class RequestManager: NSObject {
    
    var config : NSURLSessionConfiguration?
    var session: NSURLSession?
    
    
    class var sharedInstance : RequestManager {
        struct Static {
            static var token : dispatch_once_t = 0
            static var sharedInstance : RequestManager? = nil
        }
        
        dispatch_once(&Static.token) {
            Static.sharedInstance = RequestManager()
        }
        return Static.sharedInstance!
    }
    
    override init() {
        super.init()
        config = NSURLSessionConfiguration.defaultSessionConfiguration()
        session = NSURLSession(configuration: config!)
    }
    
    func getDoodle(action: (image: UIImage) -> Void) {
        let todoEndpoint: String = "http://varunsayal.com:5000/doodle"
        guard let url = NSURL(string: todoEndpoint) else {
            print("Error: cannot create URL")
            return
        }
        let urlRequest = NSURLRequest(URL: url)
        let task = self.session!.dataTaskWithRequest(urlRequest) {
            (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("error calling GET on /todos/1")
                print(error)
                return
            }
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            
            if let image = UIImage(data: responseData, scale: 1.0)
            {
                action(image: image)
            }
            
        }
        task.resume()
    }
    
    func tagDoodle(doodle: NSData){
        let tagEndpoint: String = "http://varunsayal.com:5000/tag"
        guard let tagUrl = NSURL(string: tagEndpoint) else {
            print("Error: cannot create URL")
            return
        }
        let todosUrlRequest = NSMutableURLRequest(URL: tagUrl)
        todosUrlRequest.HTTPMethod = "POST"
        todosUrlRequest.HTTPBody = doodle
        
        let task = self.session!.dataTaskWithRequest(todosUrlRequest) {
            (data, response, error) in
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            guard error == nil else {
                print("error calling POST on /todos/1")
                print(error)
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                print(responseData)
            })
        }
        task.resume()
    }


}
