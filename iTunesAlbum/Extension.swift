//
//  Extension.swift
//  iTunesAlbum
//
//  Created by Koki Tang on 28/3/2021.
//

import Foundation
import UIKit

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
