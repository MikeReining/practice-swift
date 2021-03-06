

import UIKit
import QuartzCore

class SearchResultsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, APIControllerProtocol {
    
    @IBOutlet var appTableView: UITableView
    var api: APIController?
    var albums: Album[] = []
    
    // Image Cache
    var imageCache = NSMutableDictionary()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.api = APIController(delegate:self)
        UIApplication.sharedApplication().networkActivityIndicatorVisible  = true
        self.api!.searchItunesFor("Bob Dylan")
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject) {
        var detailsViewController: DetailsViewController = segue.destinationViewController as DetailsViewController
        var albumIndex = appTableView.indexPathForSelectedRow().row
        var selectedAlbum = self.albums[albumIndex]
        detailsViewController.album = selectedAlbum
    }
    
    func didReceiveAPIResults(results: NSDictionary) {
        if results.count>0 {
            let allResults:NSDictionary[] = results["results"] as NSDictionary[]
            
            for result:NSDictionary in allResults{
                var name: String? = result["trackName"] as? String
                if !name?{
                    name = result["collectionName"] as? String
                }
                
                var price: String? = result["formattedPrice"] as? String
                if !price?{
                    price = result["collectionPrice"] as? String
                    if !price?{
                        var priceFloat: Float? = result["collectionPrice"] as? Float
                        var nf:NSNumberFormatter = NSNumberFormatter()
                        nf.maximumFractionDigits = 2
                        if !priceFloat{
                            price = "$"+nf.stringFromNumber(priceFloat)
                        }
                    }
                }
                
                let thumbnailURL: String? = result["artworkUrl60"] as? String
                let imageURL: String? = result["artworkUrl100"] as? String
                let artistURL: String? = result["artistViewUrl"] as? String
                
                var itemURL: String? = result["collectionViewUrl"] as? String
                if !itemURL? {
                    itemURL = result["trackViewUrl"] as? String
                }
                var collectionId = result["collectionId"] as? Int
                var newAlbum = Album(name: name, price: price, thumbnailImageURL: thumbnailURL, largeImageURL: imageURL, itemURL: itemURL, artistURL: artistURL, collectionId: collectionId)
                albums.append(newAlbum)
            }
            // Reload the data
            self.appTableView.reloadData()
            // Remove the network indicator
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!){
        /*// Get the row data for the selected row
        var album: Album = self.albums[indexPath.row] as Album
        
        var cellText: String? = album.title as? String
        var formattedPrice: String = album.price as String
        
        var alert: UIAlertView = UIAlertView()
        alert.title = cellText
        alert.message = formattedPrice
        alert.addButtonWithTitle("OK")
        alert.show()*/
        
    }
    
    func tableView(tableView: UITableView!, willDisplayCell cell: UITableViewCell!, forRowAtIndexPath indexPath: NSIndexPath!) {
        cell.layer.transform = CATransform3DMakeScale(0.1,0.1,1)
        UIView.animateWithDuration(0.25, animations: {
            cell.layer.transform = CATransform3DMakeScale(1,1,1)
            })
    }
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let kCellIdentifier: String = "SearchResultCell"
        var cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(kCellIdentifier) as UITableViewCell
        
        // Find this cell's album by passing in the indexPath.row to the subscript method for an array of type Album[]
        let album = self.albums[indexPath.row]
        cell.text = album.title
        cell.image = UIImage(named: "Blank52")
        cell.detailTextLabel.text = album.price
        
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            // Jump in to a background thread to get the image for this item
            
            // Grab the artworkUrl60 key to get an image URL for the app's thumbnail
            //var urlString: NSString = rowData["artworkUrl60"] as NSString
            let urlString = album.thumbnailImageURL
            
            // Check our image cache for the existing key. This is just a dictionary of UIImages
            var image: UIImage? = self.imageCache[urlString!] as? UIImage
            
            if( !image? ) {
                // If the image does not exist, we need to download it
                let imgURL: NSURL = NSURL(string: urlString)
                
                // Download an NSData representation of the image at the URL
                let request: NSURLRequest = NSURLRequest(URL: imgURL)
                let urlConnection: NSURLConnection = NSURLConnection(request: request, delegate: self)
                NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {(response: NSURLResponse!,data: NSData!,error: NSError!) -> Void in
                    if !error? {
                        image = UIImage(data: data)
                        
                        // Store the image in to our cache
                        self.imageCache[urlString!] = image
                        
                        // Sometimes this request takes a while, and it's possible that a cell could be re-used before the art is done loading.
                        // Let's explicitly call the cellForRowAtIndexPath method of our tableView to make sure the cell is not nil, and therefore still showing onscreen.
                        // While this method sounds a lot like the method we're in right now, it isn't.
                        // Ctrl+Click on the method name to see how it's defined, including the following comment:
                        /** // returns nil if cell is not visible or index path is out of range **/
                        if let albumArtsCell: UITableViewCell? = tableView.cellForRowAtIndexPath(indexPath) {
                            albumArtsCell!.image = image
                        }
                    }
                    else {
                        println("Error: \(error.localizedDescription)")
                    }
                    })
                
            }
            else {
                cell.image = image
            }
            
            
            })
        return cell
    }
}

