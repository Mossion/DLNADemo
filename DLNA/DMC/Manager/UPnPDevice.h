//
//  UPnPDevice.h
//  workTools
//
//  Created by LTMAC on 2021/9/23.
//

#import <Foundation/Foundation.h>

@interface UPnPService : NSObject
/**
 serviceId : 必有字段。服务表示符，是服务实例的唯一标识。
 serviceType : 必有字段。UPnP服务类型。
 SCPDURL : 必有字段。Service Control Protocol Description URL，获取设备描述文档URL。
 controlURL : 必有字段。向服务发出控制消息的URL。
 eventSubURL : 必有字段。订阅该服务时间的URL。
 */

/// UPnP服务类型。
@property (nonatomic, copy) NSString *_Nullable serviceType;
/// 服务表示符，是服务实例的唯一标识。
@property (nonatomic, copy) NSString *_Nullable serviceId;
/// 向服务发出控制消息的URL。
@property (nonatomic, copy) NSString *_Nullable controlURL;
/// Service Control Protocol Description URL，获取设备描述文档URL。
@property (nonatomic, copy) NSString *_Nullable SCPDURL;
/// 订阅该服务时间的URL。
@property (nonatomic, copy) NSString *_Nullable eventSubURL;

- (void)setArray:(NSArray *_Nullable)array;

@end

@interface UPnPDevice : NSObject

/// 设备名
@property (nonatomic, copy) NSString *_Nullable friendlyName;
/// 唯一标识
@property (nonatomic, copy) NSString *_Nullable uuid;
/// 包含根设备描述得URL地址  device 的webservice路径（如：http://127.0.0.1:2351/1.xml)
@property (nonatomic, copy) NSString *_Nullable location;
/// ip地址(在location内获取)
@property (nonatomic, copy) NSString *_Nullable ipString;
/// 端口（在location内获取）
@property (nonatomic, assign) UInt16 port;
/// http://ip:port， 即 location 前面部分
@property (nonatomic, copy) NSString *_Nullable httpString;


@property (nonatomic, copy) NSString *_Nullable manufacturer;
@property (nonatomic, copy) NSString *_Nullable modelName;
@property (nonatomic, copy) NSString *_Nullable manufacturerURL;
@property (nonatomic, copy) NSString *_Nullable controlURL;


/// 推送服务
@property (nonatomic, strong) UPnPService *_Nullable AVTransportService;
/// 控制服务
@property (nonatomic, strong) UPnPService *_Nullable RenderingService;

- (void)setArray:(NSArray *_Nullable)array;

@end
