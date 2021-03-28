//
//  ViewController.swift
//  iTunesAlbum
//
//  Created by Koki Tang on 28/3/2021.
//

import UIKit
import Alamofire
import AlamofireImage

class ViewController: UITableViewController, AlbumDataObserverProtocol {
    var segment: UISegmentedControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.subscribe()
        self.setupUI()
    }
    
    func setupUI() {
        segment = UISegmentedControl(items: ["All Albums", "Bookmark"])
        segment!.sizeToFit()
        segment!.selectedSegmentIndex = 0
        segment!.addTarget(self, action: #selector(onSegmentChange(_:)), for: .valueChanged)
        self.navigationItem.titleView = segment
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    @objc func onSegmentChange(_ sender: UISegmentedControl) {
        tableView.reloadData()
    }
    
    @objc func bookmark(_ sender: AlbumAccessoryButton) {
        AlbumData.shared.bookmark(album: sender.album)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.unsubscribe()
    }
    
    func subscribe() {
        NotificationCenter.default.addObserver(self, selector: #selector(albumUpdated), name: .albumUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(bookmarkUpdated), name: .bookmarkUpdated, object: nil)
    }
    
    func unsubscribe() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func albumUpdated(_ notification: Notification) {
        tableView.reloadData()
    }
    
    @objc func bookmarkUpdated(_ notification: Notification) {
        tableView.reloadData()
    }
    
    // MARK: UITableView Data Source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let albumList = AlbumData.shared.get(loadIfNoData: true) {
            if let segment = self.segment, segment.selectedSegmentIndex == 1 {
                return albumList.bookmarkCount
            }
            return albumList.resultCount
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: nil)
        if let albumList = AlbumData.shared.get() {
            var album: Album!
            if let segment = self.segment, segment.selectedSegmentIndex == 1 {
                album = albumList.bookmarkResult[indexPath.row]
            } else {
                album = albumList.results[indexPath.row]
            }
            cell.textLabel?.text = album.collectionName
            cell.detailTextLabel?.text = album.artistName
            if let albumImageUrl = album.artworkUrl100, let url = URL.init(string: albumImageUrl) {
                let placeholder = UIImage(named: "placeholder")?.resized(to: CGSize.init(width: 44, height: 44))
                let filter = AspectScaledToFillSizeWithRoundedCornersFilter.init(size: CGSize.init(width: 44, height: 44), radius: 8)
                cell.imageView?.contentMode = .scaleAspectFit
                cell.imageView?.af.setImage(withURL: url, placeholderImage: placeholder, filter: filter)
            }
            
            // Add bookmark button as accessoryView in UITableViewCell
            let button = AlbumAccessoryButton(type: .custom, album: album)
            button.setImage(UIImage(named: album.bookmarked ?? false ? "ic_bookmark_check" : "ic_bookmark_add"), for: .normal)
            button.frame = CGRect.init(x: 0, y: 0, width: 20, height: 20)
            button.isUserInteractionEnabled = true
            button.addTarget(self, action: #selector(bookmark(_:)), for: .touchUpInside)
            button.tag = indexPath.row
            cell.accessoryView = button
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

