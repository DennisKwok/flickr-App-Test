//
//  AppData.swift
//  FlickrApp
//
//  Created by Dennis Kwok on 6/12/16.
//  Copyright © 2016 Dennis. All rights reserved.
//

import Foundation

class AppData {
    
    //MARK: Shared Instance
    static let appData : AppData = AppData.init()
    
    public var loginDetails:Dictionary<String, AnyObject?>! =  nil
    public var authToken:String! = ""
    
    public func getAppData() -> AppData{
        return .appData
    }
    
    private init(){
        
    }
}
