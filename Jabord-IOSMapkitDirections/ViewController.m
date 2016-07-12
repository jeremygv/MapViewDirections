//
//  ViewController.m
//  Jabord-IOSMapkitDirections
//
//  Created by Jeremiah on 11/07/16.
//  Copyright © 2016 Jeremiah. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<MKMapViewDelegate,CLLocationManagerDelegate,UITextFieldDelegate>
{
    CLLocationManager *locationManager;
    CLGeocoder *geocoder;
    CLPlacemark *placemark;
    MKMapItem *destination;
    MKMapItem *source;
  
    CLLocation *currentLocation;
   MKPolyline *routeOverlay;
    MKRoute *currentRoute;
    CLPlacemark *placemarkSource;
    CLPlacemark *placemarkDestination;
    MKUserLocation *userLocation ;
}


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    locationManager=[[CLLocationManager alloc]init];
    locationManager.delegate=self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager requestWhenInUseAuthorization];
    [locationManager requestAlwaysAuthorization];
    
    [locationManager startUpdatingLocation];
    _sourceTextField.delegate=self;
    _destinationTextField.delegate=self;
      // Do any additional setup after loading the view, typically from a nib.
}

-(void)getDirection:(MKMapItem *)sourceItem Dest:(MKMapItem *)destinationItem
{
    
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    if ([_sourceTextField.text isEqualToString:@"Current Location"]) {
        
       [request setSource:[MKMapItem mapItemForCurrentLocation]];
    }
    else
    {
[request setSource:sourceItem];
    }
    [request setDestination:destinationItem];
    [request setTransportType:MKDirectionsTransportTypeAny];
    [request setRequestsAlternateRoutes:YES];
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
   dispatch_async (dispatch_get_main_queue(), ^{
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        if (!error) {
//            for (MKRoute *route in [response routes]) {
//                [_MapView addOverlay:[route polyline] level:MKOverlayLevelAboveRoads];
                [self showRoute:response];
          

            
//            }
        }
        else
        {
            NSLog(@"errror==%@",error);
        }
    }];});
}
-(void )showRoute:(MKDirectionsResponse *)respone
{
     for (MKRoute *route in [respone routes]) {
         currentRoute = [respone.routes firstObject];
         [self plotRouteOnMap:currentRoute];
     [_MapView addOverlay:[route polyline] level:MKOverlayLevelAboveRoads];
         for (MKRouteStep *step in [route steps]) {
             NSLog(@"%@",step.instructions);
         }
         break;
     }
    if ([_sourceTextField.text isEqualToString:@"Current Location"]) {
       userLocation =_MapView.userLocation;
       
        MKCoordinateRegion region =MKCoordinateRegionMakeWithDistance(userLocation.location.coordinate, 100 , 100);
        [_MapView setRegion:region animated:YES];

    }
    else
    {
        MKCoordinateRegion region =MKCoordinateRegionMakeWithDistance(placemarkSource.location.coordinate, 100 , 100);
        [_MapView setRegion:region animated:YES];

          }
    
}
- (void)plotRouteOnMap:(MKRoute *)route
{
    if(routeOverlay) {
        [self.MapView removeOverlay:routeOverlay];
    }
    
    // Update the ivar
    routeOverlay = route.polyline;
    
    // Add it to the map
    [self.MapView addOverlay:routeOverlay];
}

#pragma mark-MkMapKitDelegate
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
        [renderer setStrokeColor:[UIColor blueColor]];
        [renderer setLineWidth:3.0];
        return renderer;
    }
    return nil;
}
#pragma mark-TextField Delegate
//- (void)textFieldDidBeginEditing:(UITextField *)textField
//{
//    if (textField ==_sourceTextField) {
//        _sourceTextField.text=@"";
//    }
//    else
//    {
//        _destinationTextField.text=@"";
//    }
//    
//}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField ==_sourceTextField) {
        
        CLGeocoder *geocoderSource = [[CLGeocoder alloc] init];
        [geocoderSource geocodeAddressString:_sourceTextField.text completionHandler:^(NSArray *placemarks, NSError *error) {
            if (error) {
                NSLog(@"%@", error);
            } else {
                placemarkSource = [placemarks lastObject];

            }
        }];
    }
    else
    {
        
        CLGeocoder *geocoderDest = [[CLGeocoder alloc] init];
//        dispatch_async (dispatch_get_main_queue(), ^{

        [geocoderDest geocodeAddressString:_destinationTextField.text completionHandler:^(NSArray *placemarks, NSError *error) {
            if (error) {
                NSLog(@"%@", error);
            } else {
                placemarkDestination = [placemarks lastObject];
             
            }
        }];
//        });
    }
    
    
    
}
#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               initWithTitle:@"Error" message:@"Failed to Get Your Location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    
    NSLog(@"didUpdateToLocation: %@", newLocation);
 currentLocation = newLocation;
//    MKUserLocation *userLocation =_MapView.userLocation;
    
    MKCoordinateRegion region =MKCoordinateRegionMakeWithDistance(currentLocation.coordinate, 100 , 100);
    [_MapView setRegion:region animated:YES];
  
    [self sourceGeocoding:currentLocation];
   [locationManager stopUpdatingLocation];
    

}
-(void)sourceGeocoding:(CLLocation *)location
{
    geocoder =[[CLGeocoder alloc]init];
        [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
      
        if (error == nil && [placemarks count] > 0) {
            placemark = [placemarks lastObject];
         NSString *stringAddress  = [NSString stringWithFormat:@"%@ %@%@ %@%@%@",
                                       placemark.subThoroughfare, placemark.thoroughfare,
                                       placemark.postalCode, placemark.locality,
                                       placemark.administrativeArea,
                                       placemark.country];
//            NSLog(@"ADRESS--%@",stringAddress);
             _sourceTextField.text=@"Current Location";
        } else {
            NSLog(@"%@", error.debugDescription);
        }
    } ];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)searchDirection:(id)sender {
    MKPlacemark *placemarksSource;
    [_sourceTextField resignFirstResponder];
    [_destinationTextField resignFirstResponder];
   
    placemarksSource =[[MKPlacemark alloc]initWithPlacemark:placemarkSource];
    
 MKMapItem *sourceMapItem =[[MKMapItem alloc]initWithPlacemark:placemarksSource];
      MKPlacemark *placemarksDestination =[[MKPlacemark alloc]initWithPlacemark:placemarkDestination];
   MKMapItem *destinationMapItem =[[MKMapItem alloc]initWithPlacemark:placemarksDestination];
    [self getDirection:sourceMapItem Dest:destinationMapItem];
    
}

@end
