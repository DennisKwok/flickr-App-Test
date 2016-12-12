//
//  LoadingIndicator.swift
//  FlickrApp
//
//  Created by Dennis Kwok on 5/12/16.
//  Copyright © 2016 Dennis. All rights reserved.
//

import Foundation
import UIKit

class LoadingIndicator:UIView{
    var mainFrame:UIView!
    var progress:UIActivityIndicatorView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let screenWidth = frame.size.width
        let screenHeight = frame.size.height
        
        self.mainFrame = UIView.init(frame: CGRect(x: screenWidth/2 - 40, y: screenHeight/2 - 40, width: 80, height: 80))
        mainFrame.layer.cornerRadius = 10
        mainFrame.backgroundColor = UIColor.black
        mainFrame.alpha = 0.4
        self.addSubview(self.mainFrame)
        
        self.progress = UIActivityIndicatorView.init(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        self.progress.activityIndicatorViewStyle = .whiteLarge
        self.progress.startAnimating()
        mainFrame.addSubview(self.progress)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
