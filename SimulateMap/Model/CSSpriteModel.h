//
//  CSSpriteModel.h
//  SimulateMap
//
//  Created by cs on 2019/4/30.
//  Copyright © 2019 CS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSAnnotation.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CSRequestType) {
    CSRequestTypeSprite = 1,
    CSRequestTypeBoss,
    CSRequestTypeRing
};

@interface CSSpriteModel : NSObject

@property (nonatomic, assign) CSRequestType type;
@property (nonatomic, strong) NSString *searchSpriteId;
@property (nonatomic, strong) NSMutableArray <CSAnnotation *>*annotationArray;
@property (nonatomic, strong) NSMutableArray <CSAnnotation *>*annoShowArray;


- (void)handleSocketMessage:(NSData *)message;

@end

NS_ASSUME_NONNULL_END
