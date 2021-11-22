//
//  ApiHelper.swift
//  NearMeTask
//
//  Created by Aleksandar Ruzin on 20.11.21.
//

import Foundation
import UIKit

/*
 
 Helper class for making the API requests
 
 */

class ApiHelper: NSObject {
    
    var lat: String!
    var lng: String!
    
    init(latitude: Double, longitude: Double) {
        self.lat = "\(latitude)"
        self.lng = "\(longitude)"
    
    }
    
    lazy var urlComponents: URLComponents = {
        var urlBuilder = URLComponents()
        urlBuilder.scheme = Constants.API_SCHEME
        urlBuilder.host = Constants.API_HOST
        urlBuilder.path = Constants.API_PATH
        urlBuilder.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.API_CLEINT_ID),
            URLQueryItem(name: "client_secret", value: Constants.API_CLIENT_SECRET),
            URLQueryItem(name: "v", value: Constants.API_VERSION_DATE),
            URLQueryItem(name: "ll", value: "\(lat!),\(lng!)"),
            URLQueryItem(name: "intent", value: "browse"),
            URLQueryItem(name: "radius", value: Constants.API_RADIUS),
            URLQueryItem(name: "limit", value: Constants.API_LIMIT)
        ]
        return urlBuilder
    }()
    
    func getDataWith(completion: @escaping (Result<[[String: AnyObject]]>) -> Void) {
        
        guard let url = urlComponents.url else { return completion(.Error("Invalid URL, venues can't be fetched")) } // check if the URL is valid
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in // make the API call
            
            guard error == nil else { return completion(.Error(error!.localizedDescription)) }  // notify if the API is unreachable
            guard let data = data else { return completion(.Error(error?.localizedDescription ?? "There are no new venues to show"))
            }
            do { // get a JSON array with the contents of the venues as JSON array
                if let json = try JSONSerialization.jsonObject(with: data, options: [.mutableContainers]) as? [String: AnyObject] {
                    guard let responseJsonObject = json["response"]!["venues"] as? [[String: AnyObject]] else {
                        return completion(.Error(error?.localizedDescription ?? "There are no new venues to show"))
                    }
                    DispatchQueue.main.async {
                        completion(.Success(responseJsonObject))
                    }
                }
            } catch let error { //notify if the API doesn't give the expected result
                return completion(.Error(error.localizedDescription))
            }
        }.resume()
    }
}

enum Result<T> {
    case Success(T)
    case Error(String)
}
