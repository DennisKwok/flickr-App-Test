//
//  LoginPopUpView.swift
//  FlickrApp
//
//  Created by Dennis Kwok on 5/12/16.
//  Copyright © 2016 Dennis. All rights reserved.
//

//
//  ViewController.swift
//  FlickrApp
//
//  Created by Dennis Kwok on 4/12/16.
//  Copyright © 2016 Dennis. All rights reserved.
//

import UIKit
import SafariServices

extension Int {
    init(_ range: Range<Int> ) {
        let delta = range.lowerBound < 0 ? abs(range.lowerBound) : 0
        let min = UInt32(range.lowerBound + delta)
        let max = UInt32(range.upperBound   + delta)
        self.init(Int(min + arc4random_uniform(max - min)) - delta)
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

class UserPhotosViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    //View Width & Height
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    var myPhotosFeeds:[Dictionary<String, Any>] = []
    var userDetails:Dictionary<String,String> = [:]
    
    //Login UI
    var loginButton:UIButton!
    
    //After Login UI
    var loginAsLabel:UILabel!
    var logOutButton:UIButton!
    var uploadButton:UIButton!
    
    //TableView
    var feedsTable:UITableView!
    var endSpinner:UIActivityIndicatorView!
    var myPhotosPage:Int = 1
    var noPhotosLabel:UILabel!
    
    //Image Caching
    var cache:NSCache<AnyObject, AnyObject>! = NSCache()
    var loadingIndicator:LoadingIndicator!
    
    //Image Upload
    var imageToBeUploaded:UIImage!
    
    //OAuth
    var resultTokenDict:Dictionary<String, String> = [:]
    var accessTokenDict:Dictionary<String, String> = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        
        let notificationName = Notification.Name("BackFromAuthorization")
        NotificationCenter.default.addObserver(self, selector: #selector(self.getAccessToken(notification:)), name: notificationName, object: nil)
        
//        let sig:String = "GET&https://www.flickr.com/services/oauth/request_token&oauth_callback=www.example.com&oauth_consumer_key=c72a6c1c850b930522e96689d5c31e3c&oauth_nonce=\(miniToken)&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1305586162&oauth_version=1.0"
//        
//        let APISig = sig.hmac(algorithm: HMACAlgorithm.SHA1, key: "c72a6c1c850b930522e96689d5c31e3c&63113b020a5c2ddd")
//        
//        print(APISig)
        
        
    }
    
    
    func initUI(){
        self.view.backgroundColor = UIColor.white
    
        //Login UI
        loginButton = UIButton.init(frame: CGRect(x: screenWidth/2-60, y: screenHeight/2, width: 120, height: 25))
        loginButton.setTitle("Login to Flickr", for: .normal)
        loginButton.setTitleColor(UIColor.black, for: .normal)
        loginButton.layer.borderColor = UIColor.black.cgColor
        loginButton.layer.borderWidth = 1
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        loginButton.addTarget(self, action: #selector(UserPhotosViewController.loginButtonTapped(sender:)), for: .touchUpInside)
        self.view.addSubview(loginButton)
        
 
        //After Login UI
        loginAsLabel = UILabel.init(frame: CGRect(x: 15, y: 25, width: 175, height: 20))
        loginAsLabel.text = ""
        loginAsLabel.textAlignment = .left
        loginAsLabel.isHidden = true
        loginAsLabel.font = UIFont.systemFont(ofSize: 12)
        self.view.addSubview(loginAsLabel)
        
        logOutButton = UIButton.init(frame: CGRect(x: screenWidth-160, y: 25, width: 60, height: 25))
        logOutButton.setTitle("Logout", for: .normal)
        logOutButton.setTitleColor(UIColor.black, for: .normal)
        logOutButton.layer.borderColor = UIColor.black.cgColor
        logOutButton.layer.borderWidth = 1
        logOutButton.isHidden = true
        logOutButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        logOutButton.addTarget(self, action: #selector(UserPhotosViewController.logoutButtonTapped(sender:)), for: .touchUpInside)
        self.view.addSubview(logOutButton)
        
        uploadButton = UIButton.init(frame: CGRect(x: screenWidth-80, y:25, width: 60, height: 25))
        uploadButton.setTitle("Upload", for: .normal)
        uploadButton.setTitleColor(UIColor.black, for: .normal)
        uploadButton.layer.borderColor = UIColor.black.cgColor
        uploadButton.layer.borderWidth = 1
        uploadButton.isHidden = true
        uploadButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        uploadButton.addTarget(self, action: #selector(UserPhotosViewController.uploadButtonTapped(sender:)), for: .touchUpInside)
        self.view.addSubview(uploadButton)
        
        feedsTable = UITableView.init(frame: CGRect(x: 0, y: 55, width: screenWidth, height: screenHeight-55))
        feedsTable.separatorStyle = .none
        feedsTable.delegate = self
        feedsTable.dataSource = self
        feedsTable.isHidden = true
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
    
        
        noPhotosLabel = UILabel.init(frame: CGRect(x: screenWidth/2-90, y: 60, width: 180, height: 25))
        noPhotosLabel.text = "No photos"
        noPhotosLabel.textAlignment = .center
        noPhotosLabel.isHidden = true
        self.view.addSubview(noPhotosLabel)
        
        loadingIndicator = LoadingIndicator.init(frame: self.view.frame)
        loadingIndicator.isHidden = true
        self.view.addSubview(loadingIndicator)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK:Table Delegate
    private func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myPhotosFeeds.count
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
        
        let feed = self.myPhotosFeeds[indexPath.row] as Dictionary
        let photoURLString = "https://farm2.staticflickr.com/\(feed["server"] ?? "")/\(feed["id"] ?? "")_\(feed["secret"] ?? "").jpg"
        
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
            self.endSpinner.isHidden = false
            endSpinner.startAnimating()
            self.getUserPhotos()
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
    func uploadButtonTapped(sender:Any!){
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary;
//        imagePicker.allowsEditing = false
        self.present(imagePicker, animated: true, completion: nil)
    }
    

    func logoutButtonTapped(sender:Any!){
        self.resultTokenDict = [:]
        self.accessTokenDict = [:]
        self.myPhotosFeeds = []
        
        self.logOutButton.isHidden = true
        self.loginButton.isHidden = false
        
        self.loginAsLabel.isHidden = true
        self.uploadButton.isHidden = true
        self.loginAsLabel.text = "Login as "
        self.feedsTable.isHidden = true
        self.feedsTable.reloadData()
    }
    
    func loginButtonTapped(sender:Any!){
        loadingIndicator.isHidden = false
        loginToFlickr2(nonce: self.random9DigitString())
    }
    
    //MARK:Image Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        self.dismiss(animated: true, completion: nil);
        self.uploadImage(image: image)
        loadingIndicator.isHidden = false
        
    }
    
    //MARK: API - LOGIN
    func loginToFlickr2(nonce:String){
        self.resultTokenDict = [:]
        let sig:String = "GET&https%3A%2F%2Fwww.flickr.com%2Fservices%2Foauth%2Frequest_token&format%3Djson%26nojsoncallback%3D1%26oauth_callback%3Dcom.Dennis.FlickrApp%253A%252F%252F%26oauth_consumer_key%3Dc72a6c1c850b930522e96689d5c31e3c%26oauth_nonce%3D\(nonce)%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1305586162%26oauth_version%3D1.0"

        let hmacResult = self.generateHMAC(key: "63113b020a5c2ddd&", url: sig)!
        
        let url:String = "https://www.flickr.com/services/oauth/request_token?oauth_nonce=\(nonce)&oauth_timestamp=1305586162&oauth_consumer_key=c72a6c1c850b930522e96689d5c31e3c&&oauth_signature_method=HMAC-SHA1&oauth_version=1.0&oauth_signature=\(hmacResult)&oauth_callback=com.Dennis.FlickrApp://&format=json&nojsoncallback=1"
        
        print("hmac = \(hmacResult)")
        
        let request = URLRequest(url: URL(string: url)!)
        let session = URLSession.shared
        
        session.dataTask(with: request) {data, response, err in
            guard err == nil else { print(err ?? "error empty"); return }
            guard let data = data else { print("Data is empty"); return }
            
            
            let result = String(data: data, encoding:.utf8)!
            print("result :\(result)")
            
            let resultArray = result.characters.split{$0 == "&"}.map(String.init)
            
            for index in 0...resultArray.count-1 {
                let dictArray = resultArray[index].characters.split{$0 == "="}.map(String.init)
                
                if (dictArray.count == 2){
                self.resultTokenDict[dictArray[0]] = dictArray[1]
                }
                
                if self.resultTokenDict["oauth_problem"] != nil{
                    self.loginToFlickr2(nonce: self.random9DigitString())
                    return
                }
            }
            
            print(self.resultTokenDict)
            
            if let val = self.resultTokenDict["oauth_token"]{
                UIApplication.shared.open(URL(string: "https://www.flickr.com/services/oauth/authorize?oauth_token=\(val)")!, options: [:])
            }
            
            
            }.resume()
        
    }
    
    func getAccessToken(notification:NSNotification){
        self.userDetails = [:]
        
        let auth = notification.object as! String
        let resultArray = auth.characters.split{$0 == "&"}.map(String.init)
        
        for item:String in resultArray{
            let dictArray = item.characters.split{$0 == "="}.map(String.init)
            self.accessTokenDict[dictArray[0]] = dictArray[1]
        }
        
        var authVerifier = ""
        if let val = self.accessTokenDict["oauth_verifier"]{
            authVerifier = val
        }
        
        var authToken = ""
        if let val = self.accessTokenDict["oauth_token"]{
            authToken = val
        }
        
        print("token = \(authToken) && verifier = \(authVerifier)")
        let nonce = self.random9DigitString()
        var tokenSecret = "63113b020a5c2ddd&"
        
        if let val = self.resultTokenDict["oauth_token_secret"]{
            tokenSecret += val
        }
        
        let sig:String = "GET&https%3A%2F%2Fwww.flickr.com%2Fservices%2Foauth%2Faccess_token&format%3Djson%26nojsoncallback%3D1%26oauth_consumer_key%3Dc72a6c1c850b930522e96689d5c31e3c%26oauth_nonce%3D\(nonce)%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1305586162%26oauth_token%3D\(authToken)%26oauth_verifier%3D\(authVerifier)%26oauth_version%3D1.0"

        let hmacResult = self.generateHMAC(key: tokenSecret, url: sig)!
        
        let url:String = "https://www.flickr.com/services/oauth/access_token?oauth_nonce=\(nonce)&oauth_timestamp=1305586162&oauth_consumer_key=c72a6c1c850b930522e96689d5c31e3c&&oauth_signature_method=HMAC-SHA1&oauth_version=1.0&oauth_signature=\(hmacResult)&format=json&nojsoncallback=1&oauth_verifier=\(authVerifier)&oauth_token=\(authToken)"
        
        print("hmac = \(hmacResult)")
        
        let request = URLRequest(url: URL(string: url)!)
        let session = URLSession.shared
        
        session.dataTask(with: request) {data, response, err in
            guard err == nil else { print(err ?? "error empty"); return }
            guard let data = data else { print("Data is empty"); return }
            
            
            let result = String(data: data, encoding:.utf8)!
            print("access Token request : \(result)")
            
            let resultArray = result.characters.split{$0 == "&"}.map(String.init)
            
            for index in 0...resultArray.count-1 {
                let dictArray = resultArray[index].characters.split{$0 == "="}.map(String.init)
                
                if (dictArray.count == 2){
                    self.userDetails[dictArray[0]] = dictArray[1]
                }
                
                if self.userDetails["oauth_problem"] != nil{
                    print("login fail : \(dictArray[1])")
                    self.loginFail()
                    return
                }
            }
            
            print(self.userDetails)
            
            DispatchQueue.main.async() {() -> Void in
                self.loadingIndicator.isHidden = true
                self.loginButton.isHidden = true
                
                self.loginAsLabel.isHidden = false
                self.logOutButton.isHidden = false
                self.uploadButton.isHidden = false
                self.loginAsLabel.text = "Login as \(self.userDetails["username"] ?? " ")"
            }
            
            self.getUserPhotos()
            }.resume()
        
    }
    
    func loginFail(){
        let alertController = UIAlertController(title: "Login Failed", message: " \n Please try again", preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
            self.loginToFlickr2(nonce: self.random9DigitString())
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(okAction)
        DispatchQueue.main.async() {() -> Void in
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    //MARK: API - Get User photos
    func getUserPhotos(){
        DispatchQueue.main.async() {() -> Void in
            self.feedsTable.isHidden = false
            self.endSpinner.startAnimating()
        }
        let userID = self.userDetails["user_nsid"]!
        
        let nonce = self.random9DigitString()
        
        var authToken = ""
        if let val = self.userDetails["oauth_token"]{
            authToken = val
        }
        
        var tokenSecret = "63113b020a5c2ddd&"
        if let val = self.userDetails["oauth_token_secret"]{
            tokenSecret += val
        }
        
        let url:String = "https://flickr.com/services/rest/?method=flickr.people.getPhotos&api_key=c72a6c1c850b930522e96689d5c31e3c&user_id=\(userID)&page=\(myPhotosPage)&per_page=20&format=json&lang=en-us&nojsoncallback=1&oauth_nonce=\(nonce)&oauth_consumer_key=c72a6c1c850b930522e96689d5c31e3c&oauth_timestamp=1305583871&oauth_signature_method=HMAC-SHA1&oauth_version=1.0&oauth_token=\(authToken)"
        
        let request = URLRequest(url: URL(string: url)!)
        let session = URLSession.shared
        
        session.dataTask(with: request) {data, response, err in
            guard err == nil else { print(err ?? "error empty"); return }
            guard let data = data else { print("Data is empty"); return }

            
            do{
                var jsonResult = try JSONSerialization.jsonObject(with: data,options:JSONSerialization.ReadingOptions.mutableContainers) as! [String : AnyObject]
                
                print(jsonResult)
                
                let p = jsonResult["photos"] as! Dictionary<String, AnyObject>
                let photos = p["photo"] as! [Dictionary<String, Any>]
                
                if photos.count != 0{self.myPhotosPage+=1}
                
                self.myPhotosFeeds.append(contentsOf: photos)
            
                DispatchQueue.main.async() {() -> Void in
                    self.feedsTable.isHidden = false
                    self.feedsTable.reloadData()
                    self.endSpinner.stopAnimating()
                    self.endSpinner.isHidden = true
                }
            }
            catch{
                let json = String(data: data, encoding:.utf8)
                print(json ?? "getUserPhotos - fail to encode data to String")
            }
            }.resume()
    }
    
    func generateHMAC(key:String , url:String) -> String? {
        guard let keyData = key.data(using: String.Encoding.utf8) as NSData!,
            let stringData = url.data(using: String.Encoding.utf8) as NSData!,
            let outputData = NSMutableData(length: Int(CC_SHA1_DIGEST_LENGTH)) else {
                return nil
        }
        outputData.length = Int(CC_SHA1_DIGEST_LENGTH)
        
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1),
               keyData.bytes, keyData.length,
               stringData.bytes, stringData.length,
               outputData.mutableBytes)
        
        return outputData.base64EncodedString(options: [])
    }

    //MARK:API - Upload Photo
    func createRequest(image: UIImage) throws -> URLRequest {
        let nonce = self.random9DigitString()
        
        var authToken = ""
        if let val = self.userDetails["oauth_token"]{
            authToken = val
        }
        
        var tokenSecret = "63113b020a5c2ddd&"
        if let val = self.userDetails["oauth_token_secret"]{
            tokenSecret += val
        }
        
        print(tokenSecret)
        
        let sig:String = "POST&https%3A%2F%2Fup.flickr.com%2Fservices%2Fupload%2F&format%3Djson%26lang%3Den-us%26nojsoncallback%3D1%26oauth_consumer_key%3Dc72a6c1c850b930522e96689d5c31e3c%26oauth_nonce%3D\(nonce)%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1305583871%26oauth_token%3D\(authToken)%26oauth_version%3D1.0"
        
        let hmacResult = self.generateHMAC(key: tokenSecret, url: sig)!
//        let parameters = [:] as Dictionary<String,String>
        let parameters = [ "oauth_consumer_key" : "c72a6c1c850b930522e96689d5c31e3c",
                           "format" : "json",
                           "lang" : "en-us",
                           "nojsoncallback" : "1",
                           "oauth_nonce" : nonce,
                           "oauth_timestamp" : "1305583871",
                           "oauth_signature_method" : "HMAC-SHA1",
                           "oauth_version"  : "1.0",
                           "oauth_token" : authToken,
                           "oauth_signature" : hmacResult]
        
        let boundary = generateBoundaryString()
        
        let url = URL(string: "https://up.flickr.com/services/upload/?")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try createBody(with: parameters, image: image, boundary: boundary)
        
        return request
    }
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    func createBody(with parameters: [String: String]?, image: UIImage, boundary: String) throws -> Data {
        var body = Data()
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append("\(value)\r\n")
            }
        }
        
        let image_data = UIImageJPEGRepresentation(image,0.1)!
        let mimetype = "image/jpeg"
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition:form-data; name=photo; filename=\(self.random9DigitString()).jpg \r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append(image_data)
        body.append("\r\n".data(using: String.Encoding.utf8)!)
        
        body.append("--\(boundary)--\r\n")
        
        return body
    }
    
    func uploadImage(image:UIImage){
        let request: URLRequest
        
        do {
            request = try createRequest(image: image)
        } catch {
            print(error)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                // handle error here
                print(error!)
                return
            }
            
            // if response was JSON, then parse it
            
//            do {
//                let responseDictionary = try JSONSerialization.jsonObject(with: data!,options:JSONSerialization.ReadingOptions.mutableContainers)
//                print("success == \(responseDictionary)")
//
//               
            self.myPhotosPage = 1
            self.myPhotosFeeds = []
            self.getUserPhotos()
                 DispatchQueue.main.async {
                    self.loadingIndicator.isHidden = true
                     // update your UI and model objects here
                 }
//            } catch {
                print(error ?? " ")
            
                let responseString = String(data: data!, encoding: .utf8)!
                print("responseString = \(responseString)")
            self.afterUploadPopUp(message:"Upload Successful")
//                self.uploadImage(image: image)
//            }
        }
        task.resume()
    }
    
    func afterUploadPopUp(message:String){
        let alertController = UIAlertController(title: "Image Upload", message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
            alertController.dismiss(animated: true, completion: nil)
        }
        
        alertController.addAction(okAction)
        DispatchQueue.main.async() {() -> Void in
            self.present(alertController, animated: true, completion: nil)
        }
    }

    func random9DigitString() -> String {
        let min: UInt32 = 100_000_000
        let max: UInt32 = 999_999_999
        let i = min + arc4random_uniform(max - min + 1)
        return String(i)
    }
}



