

import UIKit

class PublicFeedCell: UITableViewCell{
    
    // Define label, textField etc
    var photoImgView: UIImageView!
    
    // Setup your objects
    func initCell() {
        photoImgView = UIImageView()
        photoImgView.clipsToBounds = true
        photoImgView.contentMode = .scaleAspectFill
        
        self.contentView.addSubview(photoImgView)
    }
}
//{
//    var photoImgView : UIImageView
//    var feed : Dictionary<String, String>?
//
//    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        
//        //Initialize Text Field
//        self.addSubview(self.photoImgView)
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        self.photoImgView = UIImageView();
//        
//        
//        fatalError("init(coder:) has not been implemented")
//        
//    }
////    override init(style: UITableViewCellStyle, reuseIdentifier: String!)
////    {
////        //First Call Super
////        super.init(style: style, reuseIdentifier: reuseIdentifier)
////        
////        //Initialize Text Field
////        self.photoImgView = UIImageView();
////        self.addSubview(self.photoImgView)
////    }
////    
////    
////    ///------------
////    //Method: Init with Coder
////    //Purpose:
////    //Notes: This function is apparently required; gets called by default if you don't call "registerClass, forCellReuseIdentifier" on your tableview
////    ///------------
////    required init(coder aDecoder: NSCoder)
////    {
////        //Just Call Super
////        super.init(coder: aDecoder)!
////        
////        self.photoImgView = UIImageView();
////        self.addSubview(self.photoImgView)
////    }
////    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
////        photoImgView = UIImageView.init()
//////        self.addSubview(photoImgView)
////        
////    }
////    
////    required init(coder aDecoder: NSCoder) {
//////        super.init(coder: aDecoder)!
////        
////        
////        
////    }
////    
////    override func prepareForReuse()
////    {
////        super.prepareForReuse()
////        self.photoImgView.image = nil
////    }
//}
