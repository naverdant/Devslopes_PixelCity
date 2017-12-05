//
//  Constants.swift
//  PixelCity
//
//  Created by Perfect on 2017/12/4.
//  Copyright © 2017年 Alex. All rights reserved.
//

import Foundation

let apiKey = "17a7b4b0db58b062c1f591cdbd4cd61a"

func flickrUrl(forApiKey apiKey: String, withAnnotation annotation: DroppablePin, andNumberOfPhotots number: Int) -> String {
        return "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"
}
