//
//  MoviesViewController.swift
//  Flicks
//
//  Created by Andrew Duck on 7/3/16.
//  Copyright © 2016 Andrew Duck. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    var movies = [NSDictionary]?()
    var endpoint: String!
    var searchActive: Bool = false
    var filteredData = []
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var connectionErrorView: UIView!
    @IBOutlet weak var refreshButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        
        navigationItem.titleView = searchBar
        
        refreshButton.addTarget(self, action: "refreshNetwork", forControlEvents: .TouchUpInside)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refreshControlAction:", forControlEvents: UIControlEvents.ValueChanged)
        tableView.insertSubview(refreshControl, atIndex: 0)
        
        fetchMovieData()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(searchActive) {
            return filteredData.count
        } else {
            if let movies = movies {
                return movies.count
            } else {
                return 0
            }
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        
        var movie: NSDictionary
        
        if(searchActive){
            movie = filteredData[indexPath.row] as! NSDictionary
        } else {
            movie = movies![indexPath.row]
        }

        let title = movie["title"] as! String
        
        let overview = movie["overview"] as! String
        let posterPath = movie["poster_path"] as! String
        
        if let posterPath = movie["poster_path"] as? String {
            let imageURL = "https://image.tmdb.org/t/p/w342" + posterPath
            let imageRequest = NSURLRequest(URL: NSURL(string: imageURL)!)
        
            cell.movieCoverImage.setImageWithURLRequest(
                imageRequest,
                placeholderImage: nil,
                success: { (imageRequest, imageResponse, image) -> Void in
                
                    // imageResponse will be nil if the image is cached
                    if imageResponse != nil {
                        print("Image was NOT cached, fade in image")
                        cell.movieCoverImage.alpha = 0.0
                        cell.movieCoverImage.image = image
                        UIView.animateWithDuration(0.3, animations: { () -> Void in
                            cell.movieCoverImage.alpha = 1.0
                        })
                    } else {
                        print("Image was cached so just update the image")
                        cell.movieCoverImage.image = image
                    }
                },
                failure: { (imageRequest, imageResponse, error) -> Void in
                    // Failed
            })
        }
        else {
            cell.movieCoverImage.image = nil
        }
        
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func refreshControlAction(refreshControl: UIRefreshControl) {
        fetchMovieData()
        refreshControl.endRefreshing()
    }
    
    func fetchMovieData() {
        let apiId = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string:"https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiId)")
        let request = NSURLRequest(URL: url!)
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate:nil,
            delegateQueue:NSOperationQueue.mainQueue()
        )
        
        // Display HUD right before the request is made
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                if let data = dataOrNil {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                            NSLog("response: \(responseDictionary)")
                            NSLog("url: \(url)")
                            
                            // Hide progress HUD
                            MBProgressHUD.hideHUDForView(self.view, animated: true)
                            
                            // Save data from API to movies dictionary
                            self.movies = responseDictionary["results"] as! [NSDictionary]
                            self.filteredData = self.movies!
                            
                            // Reload table view data
                            self.tableView.reloadData()
                    }
                } else {
                    
                    // Hide HUD
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    
                    // Display error
                    self.connectionErrorView.hidden = false
                }
        });
        task.resume()
    }
    
    func refreshNetwork() {
        // Attempt connection again. 
        self.connectionErrorView.hidden = true
        
        fetchMovieData()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchActive = true
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        filteredData = (movies?.filter({ (data) -> Bool in
            let tmp = data["title"] as! NSString
            let range = tmp.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch)
            return range.location != NSNotFound
        }))!
        
        if(filteredData.count == 0) {
            searchActive = false
        } else {
            searchActive = true
        }
        self.tableView.reloadData()
        
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPathForCell(cell)
        
        let movie = movies![indexPath!.row]
        
        let detailViewController = segue.destinationViewController as! DetailViewController
        
        detailViewController.movie = movie
        
        
    }
    
}
