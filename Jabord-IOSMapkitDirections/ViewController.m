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
    
    CLPlacemark *placemark;
    MKMapItem *destination;
    MKMapItem *source;
    
    CLLocation *currentLocation;
    MKPolyline *routeOverlay;
    MKRoute *currentRoute;
    CLPlacemark *placemarkSource;
    CLPlacemark *placemarkDestination;
    MKUserLocation *userLocation ;
    BOOL isSearch;
}


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    locationManager=[[CLLocationManager alloc]init];
    
    
    _sourceTextField.delegate=self;
    _destinationTextField.delegate=self;
    _destinationTextField.text=@"";
    // Do any additional setup after loading the view, typically from a nib.
}
- (void) dealloc
{
    [locationManager stopUpdatingLocation];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    
    locationManager = [CLLocationManager new];
    
    locationManager.delegate=self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager requestWhenInUseAuthorization];
    [locationManager requestAlwaysAuthorization];
    //  _locationManager.distanceFilter = kCLDistanceFilterNone;
    //_locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
    
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
    [request setTransportType:MKDirectionsTransportTypeAutomobile];
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
    NSString *eta;
    for (MKRoute *route in [respone routes]) {
        currentRoute = [respone.routes firstObject];
        NSLog(@"ETA==%f",currentRoute.expectedTravelTime);
        eta=  [self stringFromTimeInterval:currentRoute.expectedTravelTime];
        
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
        
        MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
        point.coordinate = userLocation.coordinate;
        point.title = @"ETA";
        point.subtitle = eta;
        
        [self.MapView addAnnotation:point];
    }
    else
    {
        MKCoordinateRegion region =MKCoordinateRegionMakeWithDistance(placemarkSource.location.coordinate, 100 , 100);
        [_MapView setRegion:region animated:YES];
        MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
        point.coordinate = placemarkSource.location.coordinate;
        point.title = @"ETA";
        point.subtitle = eta;
        
        [self.MapView addAnnotation:point];
        
        
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
- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
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
-(void)UpdateSouceLocation:(NSString *)sourceString
{
    
    _geocoder =[[CLGeocoder alloc]init];
    
    
    
    [_geocoder geocodeAddressString:sourceString completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        } else {
            placemarkSource = [placemarks lastObject];
            
        }
    }];
    
    
    
}
-(void)UpdateDestinationLocation:(NSString *)DestinationString
{
    
    [_geocoder geocodeAddressString:DestinationString completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        } else {
            placemarkDestination = [placemarks lastObject];
            
        }
    }];
    
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
    
    //    NSLog(@"didUpdateToLocation: %@", newLocation);
    if (!isSearch) {
        
        
        currentLocation = newLocation;
        //    MKUserLocation *userLocation =_MapView.userLocation;
        
        MKCoordinateRegion region =MKCoordinateRegionMakeWithDistance(currentLocation.coordinate, 100 , 100);
        [_MapView setRegion:region animated:YES];
        
        [self sourceGeocoding:currentLocation];
        [locationManager stopUpdatingLocation];
    }
    else
    {
        //        isSearch=NO;
        if (placemarkSource==nil) {
            [self UpdateSouceLocation:_sourceTextField.text];
        }
        if (placemarkDestination==nil) {
            
            [self UpdateDestinationLocation:_destinationTextField.text];
            
        }
        if (placemarkSource!=nil && placemarkDestination!=nil) {
            
            
            MKPlacemark *placemarksSource;
            placemarksSource =[[MKPlacemark alloc]initWithPlacemark:placemarkSource];
            
            MKMapItem *sourceMapItem =[[MKMapItem alloc]initWithPlacemark:placemarksSource];
            MKPlacemark *placemarksDestination =[[MKPlacemark alloc]initWithPlacemark:placemarkDestination];
            MKMapItem *destinationMapItem =[[MKMapItem alloc]initWithPlacemark:placemarksDestination];
            
            [self getDirection:sourceMapItem Dest:destinationMapItem];
            [locationManager stopUpdatingLocation];
        }
        //        else{
        //            isSearch=NO;
        //        }
        
    }
    
    
    
}
-(void)sourceGeocoding:(CLLocation *)location
{
    _geocoder =[[CLGeocoder alloc]init];
    [_geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if (error == nil && [placemarks count] > 0) {
            placemark = [placemarks lastObject];
            NSString *stringAddress  = [NSString stringWithFormat:@"%@ %@%@ %@%@%@",
                                        placemark.subThoroughfare, placemark.thoroughfare,
                                        placemark.postalCode, placemark.locality,
                                        placemark.administrativeArea,
                                        placemark.country];
            //            NSLog(@"ADRESS--%@",stringAddress);
            placemarkSource=placemark;
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
    isSearch=YES;
    if (![_sourceTextField.text isEqualToString:@"Current Location"]) {
        placemarkSource =nil;
    }
    placemarkDestination= nil;
    
    [locationManager startUpdatingLocation];
    
    
    
    
    
}

@end
