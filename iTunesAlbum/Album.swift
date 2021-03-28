//
//  Album.swift
//  iTunesAlbum
//
//  Created by Koki Tang on 28/3/2021.
//

import Foundation
import Alamofire

extension Notification.Name {
    static let albumUpdated = Notification.Name("albumUpdated")
    static let bookmarkUpdated = Notification.Name("bookmarkUpdated")
}
protocol ObserverProtocol {
    func subscribe()
    func unsubscribe()
}

protocol AlbumDataObserverProtocol: ObserverProtocol {
    func albumUpdated(_ notification: Notification)
    func bookmarkUpdated(_ notification: Notification)
}

class AlbumData: NSObject {
    static let shared = AlbumData()
    
    var albumList: AlbumList?
    var loading: Bool = false
    
    func get(loadIfNoData load: Bool = false) -> AlbumList? {
        if let albumList = albumList {
            return albumList
        } else {
            if load { self.load() }
            return nil
        }
    }
    
    func load() {
        // Restricted only one request to enhance performance
        if !loading {
            loading = true
            AF.request(API.albumListAPI).responseDecodable(of: AlbumList.self) { response in
                print("Loading finished")
                self.loading = false
                switch response.result {
                case .success(let data):
                    self.setData(data)
                    
                case .failure(let error):
                    debugPrint(error)
                }
            }
        }
    }
    
    func setData(_ albumList: AlbumList) {
        // Load local bookmarked items
        if let savedBookmarkData  = UserDefaults.standard.object(forKey: "BookmarkedResult") as? Data, let savedBookmarkResult = try? PropertyListDecoder().decode([Album].self, from: savedBookmarkData) {
            var filteredBookmarkResult: [Album] = []
            for (index, item) in savedBookmarkResult.enumerated() {
                if albumList.results.contains(where: { (album) -> Bool in
                    album.artistId == item.artistId && album.collectionId == item.collectionId
                }) {
                    filteredBookmarkResult.append(item)
                    albumList.results[index].bookmarked = true
                }
            }
            albumList.bookmarkResult = filteredBookmarkResult
        }
        self.albumList = albumList
        NotificationCenter.default.post(name: .albumUpdated, object: nil)
    }
    
    func bookmark(index: Int) {
        guard (index + 1) <= self.albumList?.resultCount ?? 0 else {
            print("bookmark failed")
            return
        }
        self.albumList?.results[index].bookmark()
        self.albumList?.updateBookmarkResult()
    }
}

class AlbumList: Decodable {
    var resultCount: Int = 0
    var results: [Album] = []
    var bookmarkCount: Int {
        let count = results.reduce(0, { (count, item) -> Int in
            return count + (item.bookmarked ?? false ? 1 : 0)
        })
        return count
    }
    var bookmarkResult: [Album]! = []
    
    func updateBookmarkResult() {
        let bookmarkResult = results.reduce([] as [Album], { (result, item) -> [Album] in
            if item.bookmarked ?? false {
                return result + [item]
            }
            return result
        })
        self.bookmarkResult = bookmarkResult
        
        // Save to local
        let encodedData = try? PropertyListEncoder().encode(bookmarkResult)
        let userDefaults = UserDefaults.standard
        userDefaults.set(encodedData, forKey: "BookmarkedResult")
    }
}

struct Album: Codable {
    let wrapperType: String?
    let collectionType: String?
    let artistId: Int?
    let collectionId: Int?
    let amgArtistId: Int?
    let artistName: String?
    let collectionName: String?
    let collectionCensoredName: String?
    let artistViewUrl: String?
    let collectionViewUrl: String?
    let artworkUrl60: String?
    let artworkUrl100: String?
    let collectionPrice: Float?
    let collectionExplicitness: String?
    let trackCount: Int?
    let copyright: String?
    let country: String?
    let currency: String?
    let releaseDate: String?
    let primaryGenreName: String?
    var bookmarked: Bool? = false
    
    mutating func bookmark() {
        self.bookmarked = !(self.bookmarked ?? false)
        NotificationCenter.default.post(name: .bookmarkUpdated, object: nil)
    }
}
