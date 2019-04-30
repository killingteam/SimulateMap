//
//  CSHexStrConvertDataModel.h
//  SimulateMap
//
//  Created by cs on 2019/4/26.
//  Copyright © 2019 CS. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CSHexStrConvertDataModel : NSObject

+ (NSString *)hexStringFromString:(NSString *)string;
+ (NSString *)stringFromHexString:(NSString *)hexString;
//+ (NSData *)convertHexStrToData:(NSString *)str;
+ (NSString *)convertDataToHexStr:(NSData *)data;
+ (NSString *)hexStringFormData:(NSData *)data;

+ (NSData *)convertHexStrToData:(NSString *)hexString;
+ (NSString *)hexStringWithData:(NSData *)data;
+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;
@end

NS_ASSUME_NONNULL_END
