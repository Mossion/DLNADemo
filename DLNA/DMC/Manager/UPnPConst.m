//
//  UPnPConst.m
//  workTools
//
//  Created by LTMAC on 2021/9/22.
//

#import "UPnPConst.h"

NSString *const ssdpAddress = @"239.255.255.250";  ///< 多播地址
UInt16 const ssdpPort = 1900;                                   ///< 多播端口（IPv4）或FF0x::C(IPv6）

NSString *const serviceType_RenderingControl = @"urn:schemas-upnp-org:service:RenderingControl:1"; ///< 音视频渲染器渲染服务
NSString *const serviceType_AVTransport = @"urn:schemas-upnp-org:service:AVTransport:1"; ///< 音视频传输服务（播放、暂停、恢复、结束等基础指令）

NSString *const SERVER_CALLBACK = @"/dlna/callback";

NSInteger const subscribeTimeout = 3600; ///< 订阅的时长
NSInteger const renewSubscribeTimeout = subscribeTimeout - 50; ///< 订阅到期前要续订
