//
//  Helper.swift
//  GetRecd
//
//  Created by Siraj Zaneer on 2/23/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit

func downloadArtwork(url: String, success: @escaping (UIImage) -> ()) {
    DispatchQueue.global().async {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        config.urlCache = URLCache.shared
        
        let url = URL(string: url)!
        let urlRequest = URLRequest(url: url)
        
        let task = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            if error != nil {
                return
            } else if let data = data {
                
                let cacheResponse = CachedURLResponse(response: response!, data: data)
                URLCache.shared.storeCachedResponse(cacheResponse, for: urlRequest)
                
                guard let image = UIImage(data: data) else {
                    return
                }
                success(image)
            }
        })
        task.resume()
    }
}
