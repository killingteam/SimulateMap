//
//  ViewController.m
//  SimulateMap
//
//  Created by cs on 2019/4/19.
//  Copyright © 2019 CS. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>
#import "CSAnnotation.h"
#import "JZLocationConverter.h"
#import "SRWebSocket.h"
#import "CSHexStrConvertDataModel.h"
#import "YYModel.h"
#import "CSSpriteModel.h"

@interface ViewController () <MKMapViewDelegate, CLLocationManagerDelegate, SRWebSocketDelegate,
NSTextFieldDelegate>
{
    BOOL isOpen;
}
@property (weak) IBOutlet NSButton *socketButton;

@property (weak) IBOutlet MKMapView *mapView;
@property (weak) IBOutlet NSButton *findMe;
@property (weak) IBOutlet NSClickGestureRecognizer *click;
@property (nonatomic, strong) NSMutableArray <CSAnnotation *>*annotationArray;
@property (nonatomic, strong) MKPolyline *polyline;
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (weak) IBOutlet NSTextField *searchTextField;
@property (nonatomic, strong) SRWebSocket *webSocket;
@property (weak) IBOutlet NSTextField *spriteTextField;
@property (nonatomic, strong) CSSpriteModel *model;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    
    [self.mapView addGestureRecognizer:self.click];
    self.annotationArray = [NSMutableArray new];
    self.geocoder =[[CLGeocoder alloc]init];
    
    self.webSocket = [[SRWebSocket alloc] initWithURL:[[NSURL alloc] initWithString:@"wss://publicld.gwgo.qq.com/?account_value=0&account_type=0&appid=0&token=0"]];
    self.webSocket.delegate = self;
    [self.webSocket open];
    self.searchTextField.delegate = self;
    self.spriteTextField.delegate = self;
    self.model = [CSSpriteModel new];
    
}
- (IBAction)pressSocketButton:(NSButton *)sender {
    self.model.type = CSRequestTypeSprite;
    self.model.searchSpriteId = self.spriteTextField.stringValue;
    [self openSocket];
    
    CLLocationCoordinate2D centerCoordinate = [JZLocationConverter gcj02ToWgs84:self.mapView.centerCoordinate];
    NSMutableString *longtitudeStr = [NSMutableString stringWithString:[NSString stringWithFormat:@"%.6f", centerCoordinate.longitude]];
    [longtitudeStr replaceOccurrencesOfString:@"." withString:@"" options:NSLiteralSearch range:NSMakeRange(0, longtitudeStr.length)];

    NSMutableString *latitudeStr = [NSMutableString stringWithString:[NSString stringWithFormat:@"%.6f", centerCoordinate.latitude]];
    [latitudeStr replaceOccurrencesOfString:@"." withString:@"" options:NSLiteralSearch range:NSMakeRange(0, latitudeStr.length)];

    NSString *requestStr = [NSString stringWithFormat:@"b{\"request_type\":\"1001\",\"longtitude\":%@,\"latitude\":%@,\"requestid\":135070,\"platform\":0}", longtitudeStr, latitudeStr];
//    NSString *requestStr = @"b{\"request_type\":\"1001\",\"longtitude\":113336575,\"latitude\":23190997,\"requestid\":135070,\"platform\":0}";
    NSString *hexStr = [CSHexStrConvertDataModel hexStringFromString:requestStr];
    NSMutableString *mutableHexStr = [NSMutableString string];
    for (int i = 0; i < hexStr.length % 16; i++) {
        [mutableHexStr appendString:@"0"];
    }
    [mutableHexStr appendString:hexStr];
    NSData *data = [CSHexStrConvertDataModel convertHexStrToData:mutableHexStr];
    if (self.webSocket.readyState == SR_OPEN) {
        [self.webSocket send:data];
    }
    
}
- (IBAction)pressFindMe:(id)sender {
    self.mapView.showsUserLocation = YES;
    [self.mapView setCenterCoordinate:self.mapView.userLocation.location.coordinate animated:YES];
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.location.coordinate, 500, 500);
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
    [self.mapView setRegion:adjustedRegion animated:YES];
    
}
- (IBAction)clickAction:(id)sender {
    
    CGPoint point = [self.click locationInView:self.mapView];
    CSAnnotation *annotation = [CSAnnotation new];
    annotation.coordinate = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    [self.mapView addAnnotation:annotation];
    [self.annotationArray addObject:annotation];
    [self.mapView removeOverlay:self.polyline];
    [self addOverLayer];
    
}
- (IBAction)cleanLastAction:(NSButton *)sender {
    [self.mapView removeAnnotation:self.annotationArray.lastObject];
    [self.annotationArray removeLastObject];
    [self.mapView removeOverlay:self.polyline];
    [self addOverLayer];
}
- (IBAction)cleanAllAction:(NSButton *)sender {
    [self.mapView removeAnnotations:self.annotationArray];
    [self.annotationArray removeAllObjects];
    [self.mapView removeOverlay:self.polyline];
}
- (IBAction)printGPX:(NSButton *)sender {
    NSDate *now = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [docPath stringByAppendingPathComponent:@"test.gpx"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    
    NSMutableString *contentStr = [NSMutableString string];
    NSString *header = @"<?xml version=\"1.0\"?>\n<gpx version=\"1.1\" creator=\"Xcode\">\n";
    [contentStr appendString:header];
    
    NSMutableArray <CLLocation *>*locationArr = [NSMutableArray array];
    for (CSAnnotation *annotation in self.annotationArray) {
        CLLocationCoordinate2D targetCoord = [JZLocationConverter gcj02ToWgs84:annotation.coordinate];
        CLLocation *location = [[CLLocation alloc] initWithLatitude:targetCoord.latitude longitude:targetCoord.longitude];
        
        [locationArr addObject:location];
    }
//    NSArray *chinaArr = [ViewController translateWGS_RunPathArrayToGCJ_RunPathArray:locationArr];
    __block NSDate *tempDate = nil;
    __block CLLocation *lastLocation = nil;
    [locationArr enumerateObjectsUsingBlock:^(CLLocation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0) {
            tempDate = now;
        } else {
            CLLocationDistance distance = [obj distanceFromLocation:lastLocation];
            int time = distance / 20;
            if (distance < 10) {
                time = 3;
            }
            
            tempDate = [tempDate dateByAddingTimeInterval:time];
        }
        lastLocation = obj;
        NSString *current = [formatter stringFromDate:tempDate];
        NSString *annotationStr = [NSString stringWithFormat:@"<wpt lat=\"%@\" lon=\"%@\">\n<time>%@</time>\n</wpt>\n", @(obj.coordinate.latitude), @(obj.coordinate.longitude), current];
        [contentStr appendString:annotationStr];
    }];
    
    [contentStr appendString:@"</gpx>"];
    [contentStr writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"filePath = %@", filePath);
    
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[[NSURL fileURLWithPath:filePath]]];
}
- (IBAction)pressYuLinButton:(NSButton *)sender {
    self.model.type = CSRequestTypeBoss;
    [self openSocket];
    
    CLLocationCoordinate2D centerCoordinate = [JZLocationConverter gcj02ToWgs84:self.mapView.centerCoordinate];
    NSMutableString *longtitudeStr = [NSMutableString stringWithString:[NSString stringWithFormat:@"%.6f", centerCoordinate.longitude]];
    [longtitudeStr replaceOccurrencesOfString:@"." withString:@"" options:NSLiteralSearch range:NSMakeRange(0, longtitudeStr.length)];
    
    NSMutableString *latitudeStr = [NSMutableString stringWithString:[NSString stringWithFormat:@"%.6f", centerCoordinate.latitude]];
    [latitudeStr replaceOccurrencesOfString:@"." withString:@"" options:NSLiteralSearch range:NSMakeRange(0, latitudeStr.length)];
    
    NSString *requestStr = [NSString stringWithFormat:@"b{\"request_type\":\"1002\",\"longtitude\":%@,\"latitude\":%@,\"requestid\":135070,\"platform\":0}", longtitudeStr, latitudeStr];
    //    NSString *requestStr = @"b{\"request_type\":\"1001\",\"longtitude\":113336575,\"latitude\":23190997,\"requestid\":135070,\"platform\":0}";
    NSString *hexStr = [CSHexStrConvertDataModel hexStringFromString:requestStr];
    NSMutableString *mutableHexStr = [NSMutableString string];
    for (int i = 0; i < hexStr.length % 16; i++) {
        [mutableHexStr appendString:@"0"];
    }
    [mutableHexStr appendString:hexStr];
    NSData *data = [CSHexStrConvertDataModel convertHexStrToData:mutableHexStr];
    if (self.webSocket.readyState == SR_OPEN) {
        [self.webSocket send:data];
    }
}

- (void)addOverLayer {
    NSArray <CSAnnotation *>*layerArray = @[];
    if (self.annotationArray.count > 0) {
        layerArray = self.annotationArray;
    } else if (self.model.annotationArray.count > 0) {
        layerArray = self.model.annotationArray;
    } else if (self.model.annoShowArray.count > 0) {
        layerArray = self.model.annoShowArray;
    }
    
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)malloc(sizeof(CLLocationCoordinate2D) * layerArray.count);
    
    for (int i = 0; i < layerArray.count; i++) {
        coordinates[i] = layerArray[i].coordinate;
    }
    self.polyline = [MKPolyline polylineWithCoordinates:coordinates count:layerArray.count];
    free(coordinates);
    [self.mapView addOverlay:self.polyline];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    //    NSLog(@"%@ ----- %@", self, NSStringFromSelector(_cmd));
    if ([overlay class] == [MKPolyline class])
    {
        MKPolylineRenderer *polylineView = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        polylineView.strokeColor = [NSColor redColor];
        polylineView.lineWidth = 5;
        return polylineView;
    }else if ([overlay isKindOfClass:[MKPolyline class]])
    {
        MKPolylineRenderer *polylineView = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        polylineView.strokeColor = [NSColor redColor];
        polylineView.lineWidth = 5;
        return polylineView;
    }
    return nil;
}
- (IBAction)searchAction:(NSButton *)sender {
    [self getCoordinateByAddress:self.searchTextField.stringValue];
}

#pragma mark 根据地名确定地理坐标
-(void)getCoordinateByAddress:(NSString *)address{
    if (address.length == 0) {
        return;
    }
    //地理编码
    [_geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error) {
        //取得第一个地标，地标中存储了详细的地址信息，注意：一个地名可能搜索出多个地址
        CLPlacemark *placemark=[placemarks firstObject];
        
        CLLocation *location=placemark.location;//位置
        CLRegion *region=placemark.region;//区域
        NSDictionary *addressDic= placemark.addressDictionary;//详细地址信息字典,包含以下部分信息
        //        NSString *name=placemark.name;//地名
        //        NSString *thoroughfare=placemark.thoroughfare;//街道
        //        NSString *subThoroughfare=placemark.subThoroughfare; //街道相关信息，例如门牌等
        //        NSString *locality=placemark.locality; // 城市
        //        NSString *subLocality=placemark.subLocality; // 城市相关信息，例如标志性建筑
        //        NSString *administrativeArea=placemark.administrativeArea; // 州
        //        NSString *subAdministrativeArea=placemark.subAdministrativeArea; //其他行政区域信息
        //        NSString *postalCode=placemark.postalCode; //邮编
        //        NSString *ISOcountryCode=placemark.ISOcountryCode; //国家编码
        //        NSString *country=placemark.country; //国家
        //        NSString *inlandWater=placemark.inlandWater; //水源、湖泊
        //        NSString *ocean=placemark.ocean; // 海洋
        //        NSArray *areasOfInterest=placemark.areasOfInterest; //关联的或利益相关的地标
        NSLog(@"位置:%@,区域:%@,详细信息:%@",location,region,addressDic);
        [self.mapView setCenterCoordinate:location.coordinate animated:YES];
        
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, region.radius, region.radius);
        MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
        [self.mapView setRegion:adjustedRegion animated:YES];
    }];
}

#pragma mark - SRWebSocketDelegate
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSLog(@"%@", message);
    [self.mapView removeAnnotations:self.annotationArray];
    [self.mapView removeOverlay:self.polyline];
    [self.annotationArray removeAllObjects];
    if ([message isKindOfClass:[NSData class]]) {
        [self.model handleSocketMessage:message];
        if (self.model.type == CSRequestTypeSprite) {
            for (CSAnnotation *anno in self.model.annotationArray) {
                [self.mapView addAnnotation:anno];
            }
            [self addOverLayer];
        } else if (self.model.type == CSRequestTypeBoss) {
            
        }
    }
}


- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    isOpen = YES;
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    [self openSocket];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    isOpen = NO;
}

- (void)openSocket {
    if (self.webSocket.readyState == SR_CLOSED) {
        self.webSocket = nil;
        self.webSocket = [[SRWebSocket alloc] initWithURL:[[NSURL alloc] initWithString:@"wss://publicld.gwgo.qq.com/?account_value=0&account_type=0&appid=0&token=0"]];
        self.webSocket.delegate = self;
        [self.webSocket open];
    }

}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    if (obj.object == self.searchTextField) {
        [self searchAction:nil];
    } else if (obj.object == self.spriteTextField) {
        [self pressSocketButton:nil];
    }
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
