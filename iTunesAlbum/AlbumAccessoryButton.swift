//
//  AlbumAccessoryButton.swift
//  iTunesAlbum
//
//  Created by Koki Tang on 29/3/2021.
//

import Foundation
import UIKit

class AlbumAccessoryButton: UIButton {
    var album: Album!
    
    public convenience init(type buttonType: UIButton.ButtonType, album: Album) {
        self.init(type: buttonType)
        self.album = album
    }
}
