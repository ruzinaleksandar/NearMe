//
//  Extensions.swift
//  NearMeTask
//
//  Created by Aleksandar Ruzin on 20.11.21.
//

import Foundation
import UIKit

/*
 
 UIImageView extension for loading images. If the image was once downloaded and cached it will be served from the cache, if the image is requested for the first time it will be loaded from it's URL and saved in the cache.
 
 */

let imageCache = NSCache<NSString, UIImage>()

extension UIImageView {

    func loadImageUsingCacheWithURLString(_ URLString: String, uiImage: UIImage?) {
        
        self.image = nil
        //check if the image exits in the cache, it's URL is used as identificator
        if let cachedImage = imageCache.object(forKey: NSString(string: URLString))?.withRenderingMode(.alwaysTemplate) { //render the image as template image so it's tint color can be changed
            self.image = cachedImage
            return
        }
        // image is not found in the cache, loadin it from URL
        if let url = URL(string: URLString) {
            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                
                if error != nil { // there was an error loading the image
                    print("ERROR LOADING IMAGE FROM URL: \(String(describing: error))")
                    DispatchQueue.main.async {
                        self.image = uiImage
                    }
                    return
                }
                DispatchQueue.main.async { // image was sucessfully downloaded and saved into cache asynchronous
                    if let data = data {
                        if let downloadedImage = UIImage(data: data)?.withRenderingMode(.alwaysTemplate) {
                            imageCache.setObject(downloadedImage, forKey: NSString(string: URLString))
                            self.image = downloadedImage
                        }
                    }
                }
            }).resume()
        }
    }
}
