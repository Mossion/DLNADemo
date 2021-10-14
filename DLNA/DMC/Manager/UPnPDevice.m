//
//  UPnPDevice.m
//  workTools
//
//  Created by LTMAC on 2021/9/23.
//

#import "UPnPDevice.h"
#import "GDataXMLNode.h"
#import "UPnPConst.h"

@implementation UPnPService

- (void)setArray:(NSArray *)array {
    for (int m = 0; m < array.count; m++) {
        GDataXMLNode *ele = array[m];
        if ([ele.name isEqualToString:@"serviceType"]) {
            self.serviceType = ele.stringValue;
        }
        if ([ele.name isEqualToString:@"serviceId"]) {
            self.serviceId = ele.stringValue;
        }
        if ([ele.name isEqualToString:@"controlURL"]) {
            self.controlURL = ele.stringValue;
        }
        if ([ele.name isEqualToString:@"SCPDURL"]) {
            self.SCPDURL = ele.stringValue;
        }
        if ([ele.name isEqualToString:@"eventSubURL"]) {
            self.eventSubURL = ele.stringValue;
        }
    }
}

@end

@implementation UPnPDevice

- (void)setLocation:(NSString *)location {
    _location = location;
    // http://192.168.199.180:49152/description.xml
    // 要获取IP和端口，获取第三个 / 的位置
    NSMutableArray *backslashArray = [self getRangeStr:location findText:@"/"];
    if (backslashArray.count >= 3) {
        NSInteger index = [backslashArray[2] integerValue];
        NSString *ipAndPort = [location substringToIndex:index];
        self.httpString = ipAndPort;
        NSArray *colonArray = [self getRangeStr:ipAndPort findText:@":"];
        if (colonArray.count >= 2) {
            NSInteger colonIndex = [colonArray[1] integerValue];
            NSString *ipString = [ipAndPort substringToIndex:colonIndex];
            NSString *portString = [ipAndPort substringFromIndex:colonIndex+1];
            self.ipString = [ipString substringFromIndex:7];
            self.port = [portString integerValue];
        }
    }
}

- (void)setArray:(NSArray *)array {
    for (int i = 0; i < array.count; i++) {
        GDataXMLNode *ele = array[i];
        if ([ele.name isEqualToString:@"friendlyName"]) {
            self.friendlyName = ele.stringValue;
        }
        if ([ele.name isEqualToString:@"manufacturer"]) {
            self.manufacturer = ele.stringValue;
        }
        if ([ele.name isEqualToString:@"modelName"]) {
            self.modelName = ele.stringValue;
        }
        if ([ele.name isEqualToString:@"manufacturerURL"]) {
            self.manufacturerURL = ele.stringValue;
        }
        if ([ele.name isEqualToString:@"controlURL"]) {
            self.controlURL = ele.stringValue;
        }
        if ([ele.name isEqualToString:@"serviceList"]) {
            NSArray *children = ele.children;
            [self handleServiceList:children];
        }
    }
}

- (void)handleServiceList:(NSArray *)serviceList {
    for (int j = 0; j < serviceList.count; j++) {
        GDataXMLNode *ele = serviceList[j];
        if ([ele.name isEqualToString:@"service"] == NO) {
            continue;
        }
        NSArray *serviceChildren = ele.children;
        if ([ele.stringValue rangeOfString:serviceType_AVTransport].location != NSNotFound) {
            [self.AVTransportService setArray:serviceChildren];
        }
        if ([ele.stringValue rangeOfString:serviceType_RenderingControl].location != NSNotFound) {
            [self.RenderingService setArray:serviceChildren];
        }
    }
}

#pragma mark - 获取这个字符串ASting中的所有abc的所在的index
- (NSMutableArray *)getRangeStr:(NSString *)text findText:(NSString *)findText {
    NSMutableArray *arrayRanges = [NSMutableArray arrayWithCapacity:3];
    if (findText == nil && [findText isEqualToString:@""]) {
        return nil;
    }
    NSRange rang = [text rangeOfString:findText]; //获取第一次出现的range
    if (rang.location != NSNotFound && rang.length != 0) {
        [arrayRanges addObject:[NSNumber numberWithInteger:rang.location]];//将第一次的加入到数组中
        NSRange rang1 = {0,0};
        NSInteger location = 0;
        NSInteger length = 0;
        for (int i = 0;; i++) {
            if (0 == i) {
               //去掉这个abc字符串
                location = rang.location + rang.length;
                length = text.length - rang.location - rang.length;
                rang1 = NSMakeRange(location, length);
            } else {
                location = rang1.location + rang1.length;
                length = text.length - rang1.location - rang1.length;
                rang1 = NSMakeRange(location, length);
            }
            //在一个range范围内查找另一个字符串的range
            rang1 = [text rangeOfString:findText options:NSCaseInsensitiveSearch range:rang1];
            if (rang1.location == NSNotFound && rang1.length == 0) {
                break;
            } else {
                //添加符合条件的location进数组
                [arrayRanges addObject:[NSNumber numberWithInteger:rang1.location]];
            }
        }
        return arrayRanges;
    }
    return nil;
}

#pragma mark - lazy load
- (UPnPService *)AVTransportService {
    if (_AVTransportService) {
        return _AVTransportService;
    }
    _AVTransportService = [[UPnPService alloc] init];
    return _AVTransportService;
}

- (UPnPService *)RenderingService {
    if (_RenderingService) {
        return _RenderingService;
    }
    _RenderingService = [[UPnPService alloc] init];
    return _RenderingService;
}

@end
