//
//  CSSpriteModel.m
//  SimulateMap
//
//  Created by cs on 2019/4/30.
//  Copyright © 2019 CS. All rights reserved.
//

#import "CSSpriteModel.h"
#import "CSHexStrConvertDataModel.h"

@implementation CSSpriteModel

- (instancetype)init {
    if (self = [super init]) {
        self.annotationArray = [NSMutableArray array];
        self.annoShowArray = [NSMutableArray array];
    }
    return self;
}

- (void)handleSocketMessage:(NSData *)message {
    NSString *byteStr = [CSHexStrConvertDataModel convertDataToHexStr:message];
    
    NSString *json = [CSHexStrConvertDataModel stringFromHexString:byteStr];
    NSRange headerRange = [json rangeOfString:@"{" options:NSLiteralSearch];
    json = [json substringFromIndex:headerRange.location];
    //        NSRange footerRange = [json rangeOfString:@"}," options:NSBackwardsSearch];
    //        json = [json substringFromIndex:footerRange.location];
    NSDictionary *obj = [CSHexStrConvertDataModel dictionaryWithJsonString:json];
    if (self.type == CSRequestTypeSprite) {
        [self findSpriteListWithDic:obj];
    } else if (self.type == CSRequestTypeBoss) {
        [self findBossWithDic:obj];
    }
}

- (void)findBossWithDic:(NSDictionary *)obj {
    NSArray *bossArr = obj[@"dojo_list"];
    for (NSDictionary *dic in bossArr) {
        
        //state = 0 擂台
        //state = 1 神石 freshtime 孵化时间
        //state = 2 神灵 bossid，freshtime 消失时间
        
        long state = [dic[@"state"] longValue];
        
        if (state == 1 && self.type == CSRequestTypeRing) {
            long latitudeValue = [dic[@"latitude"] longValue];
            NSMutableString *latitudeStr = [NSMutableString stringWithString:@(latitudeValue).stringValue];
            if (latitudeStr.length <= 6) {
                continue;
            }
            [latitudeStr insertString:@"." atIndex:latitudeStr.length - 6];
            
            long longtitudeValue = [dic[@"longtitude"] longValue];
            NSMutableString *longtitudeStr = [NSMutableString stringWithString:@(longtitudeValue).stringValue];
            if (longtitudeStr.length <= 6) {
                continue;
            }
            [longtitudeStr insertString:@"." atIndex:longtitudeStr.length - 6];
            
            CLLocationCoordinate2D coor = CLLocationCoordinate2DMake(latitudeStr.doubleValue, longtitudeStr.doubleValue);
            CSAnnotation *anno = [CSAnnotation new];
            anno.coordinate = coor;
            [self.annoShowArray addObject:anno];
        }
        
        if (state == 2 && self.type == CSRequestTypeBoss) {
            long latitudeValue = [dic[@"latitude"] longValue];
            NSMutableString *latitudeStr = [NSMutableString stringWithString:@(latitudeValue).stringValue];
            if (latitudeStr.length <= 6) {
                continue;
            }
            [latitudeStr insertString:@"." atIndex:latitudeStr.length - 6];
            
            long longtitudeValue = [dic[@"longtitude"] longValue];
            NSMutableString *longtitudeStr = [NSMutableString stringWithString:@(longtitudeValue).stringValue];
            if (longtitudeStr.length <= 6) {
                continue;
            }
            [longtitudeStr insertString:@"." atIndex:longtitudeStr.length - 6];
            
            CLLocationCoordinate2D coor = CLLocationCoordinate2DMake(latitudeStr.doubleValue, longtitudeStr.doubleValue);
            CSAnnotation *anno = [CSAnnotation new];
            anno.coordinate = coor;
            [self.annoShowArray addObject:anno];
        }
        

    }
}

//找妖怪
- (void)findSpriteListWithDic:(NSDictionary *)obj {
    NSArray *spriteArr = obj[@"sprite_list"];
    NSString *searchSpriteId = self.searchSpriteId;
    if (searchSpriteId.length == 0) {
        return;
    }
    for (NSDictionary *spriteDic in spriteArr) {
        long spriteID = [spriteDic[@"sprite_id"] longValue];
        if (spriteID == searchSpriteId.integerValue) {
            long latitudeValue = [spriteDic[@"latitude"] longValue];
            NSMutableString *latitudeStr = [NSMutableString stringWithString:@(latitudeValue).stringValue];
            [latitudeStr insertString:@"." atIndex:latitudeStr.length - 6];
            
            long longtitudeValue = [spriteDic[@"longtitude"] longValue];
            NSMutableString *longtitudeStr = [NSMutableString stringWithString:@(longtitudeValue).stringValue];
            [longtitudeStr insertString:@"." atIndex:longtitudeStr.length - 6];
            
            CLLocationCoordinate2D coor = CLLocationCoordinate2DMake(latitudeStr.doubleValue, longtitudeStr.doubleValue);
            CSAnnotation *anno = [CSAnnotation new];
            anno.coordinate = coor;
            [self.annotationArray addObject:anno];
            [self.annotationArray addObject:anno];

        }
    }
    

}


@end
