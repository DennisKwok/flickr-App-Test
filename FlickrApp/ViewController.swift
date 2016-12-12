//
//  ViewController.swift
//  FlickrApp
//
//  Created by Dennis Kwok on 4/12/16.
//  Copyright © 2016 Dennis. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    //View Width & Height
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    var flickrFeeds:[Dictionary<String, Any>] = []
    
    //TableView
    var feedsTable:UITableView!
    var endSpinner:UIActivityIndicatorView!
    
    //Image Chaching
    var cache:NSCache<AnyObject, AnyObject>! = NSCache()
    
    var loadingIndicator:LoadingIndicator!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        initUI()
        getPublicPhotos();
    }
    
    func initUI(){
        let title:UILabel = UILabel.init(frame: CGRect(x: screenWidth/2 - 70, y: 18, width: 140, height: 35))
        title.text = "Public Photos"
        title.textAlignment = .center
        self.view.addSubview(title)
        
        let loginButton:UIButton = UIButton.init(frame: CGRect(x: screenWidth-100, y: 10, width: 100, height: 55))
        loginButton.setTitle("My Photos >", for: .normal)
        loginButton.setTitleColor(UIColor.black, for: .normal)
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        loginButton.addTarget(self, action:#selector(ViewController.loginButtonTapped(sender:)), for: .touchUpInside)
        self.view.addSubview(loginButton)
        
        feedsTable = UITableView.init(frame: CGRect(x: 0, y: 55, width: screenWidth, height: screenHeight-55))
        feedsTable.separatorStyle = .none
        feedsTable.delegate = self
        feedsTable.dataSource = self
        self.view.addSubview(feedsTable)
        
        //Loading Indicator for load more
        //as Footer
        let footer:UIView = UIView.init(frame: CGRect(x: 0, y: 0, width: self.screenWidth, height: 30))
        footer.backgroundColor = UIColor.white
        endSpinner = UIActivityIndicatorView.init(frame: footer.frame)
        endSpinner.activityIndicatorViewStyle = .gray
        footer.addSubview(endSpinner)
        
        feedsTable.tableFooterView = endSpinner
        feedsTable.register(PublicFeedCell.classForCoder(), forCellReuseIdentifier: "PublicFeedCell")
        
        loadingIndicator = LoadingIndicator.init(frame: self.view.frame)
        self.view.addSubview(loadingIndicator)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    //MARK: API
    func getPublicPhotos(){
        let url :String = "https://api.flickr.com/services/feeds/photos_public.gne?api_key=c72a6c1c850b930522e96689d5c31e3c&format=json&nojsoncallback=1&lang=en-us"
        
        let request = URLRequest(url: URL(string: url)!)
        let session = URLSession.shared
        
        session.dataTask(with: request as URLRequest) { data, response, err in
            guard let data = data else { print("Data is empty"); return }
            guard err == nil else { print(err ?? "Error in request"); return }
            
            do{
                var jsonResult = try JSONSerialization.jsonObject(with: data,options:JSONSerialization.ReadingOptions.mutableContainers) as! [String : AnyObject]
                
                self.flickrFeeds.append(contentsOf: jsonResult["items"] as! [Dictionary<String, Any>])
                DispatchQueue.main.async() {() -> Void in
                    self.feedsTable.reloadData()
                    self.loadingIndicator.isHidden = true
                }
            }
            catch{
                //Inconsistency of the JSON result from the API
                //If response can't be parsed to JSON, Call the API again
                self.getPublicPhotos()
//                print("reloading Feed")
            }
            }.resume()
    }
    
    func parseJSON(data: Data){
        do{
            var jsonResult = try JSONSerialization.jsonObject(with: data,options:JSONSerialization.ReadingOptions.mutableContainers) as! [String : AnyObject]
            self.flickrFeeds = jsonResult["items"] as! [Dictionary<String, Any>]
            DispatchQueue.main.async() {() -> Void in self.feedsTable.reloadData()}
        }
        catch{
            self.parseJSON(data: data)
        }
    }
    
    //MARK:Table Delegate
    private func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return flickrFeeds.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 235
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PublicFeedCell = PublicFeedCell()
        cell.initCell()
        cell.photoImgView.frame = CGRect(x:screenWidth*0.05, y: 5, width: screenWidth*0.9, height: 225)
        cell.photoImgView.clipsToBounds = true
        cell.photoImgView.contentMode = .scaleAspectFill
        
        let feed = self.flickrFeeds[indexPath.row] as Dictionary
        let media = feed["media"] as? Dictionary<String, String> ?? Dictionary()
        let photoURLString = media["m"] ?? ""
        
        if (self.cache.object(forKey: (indexPath as NSIndexPath).row as AnyObject) != nil){
            cell.photoImgView.image = self.cache.object(forKey: (indexPath as IndexPath).row as AnyObject) as? UIImage
        }
        else{
            imageDownload(url: URL(string:photoURLString)!, imageView: cell.photoImgView, indexPath: indexPath)
        }
        return cell
    }
    
    //Load more
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offset:CGPoint = scrollView.contentOffset
        let bounds:CGRect = scrollView.bounds
        let size:CGSize = scrollView.contentSize
        let inset:UIEdgeInsets = scrollView.contentInset
        
        let y = offset.y + bounds.size.height - inset.bottom
        let h = size.height
        
        if (y > h){
            endSpinner.startAnimating()
            self.getPublicPhotos()
        }
    }
    
    func imageDownload(url: URL, imageView: UIImageView, indexPath: IndexPath) {
        imageView.backgroundColor = UIColor.lightGray
        
        URLSession.shared.dataTask(with:url, completionHandler: { (data, response, error) -> Void in
            guard let data = data, error == nil else { return }
            
            self.cache.setObject(UIImage(data: data)!, forKey: (indexPath as IndexPath).row as AnyObject)
            DispatchQueue.main.async() {() -> Void in imageView.image = UIImage(data: data)}
        }).resume()
    }
    
    //MARK:Button Handler
    func loginButtonTapped(sender:Any!){
        let userPhotosVC:UserPhotosViewController = UserPhotosViewController()
        self.navigationController?.navigationBar.isHidden = true
        self.navigationController?.pushViewController(userPhotosVC, animated: true)
    }
    
}


