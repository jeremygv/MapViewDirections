//
//  ViewController.h
//  Jabord-IOSMapkitDirections
//
//  Created by Jeremiah on 11/07/16.
//  Copyright © 2016 Jeremiah. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import<CoreLocation/CoreLocation.h>
@interface ViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITextField *sourceTextField;
@property (strong, nonatomic) IBOutlet UITextField *destinationTextField;


@property (strong, nonatomic) IBOutlet MKMapView *MapView;
- (IBAction)searchDirection:(id)sender;

@end

