//
//  UPnPConst.h
//  workTools
//
//  Created by LTMAC on 2021/9/22.
//

#import <Foundation/Foundation.h>

extern NSString *const ssdpAddress;  ///< IP地址
extern UInt16 const ssdpPort; ///< 端口

extern NSString *const serviceType_RenderingControl;
extern NSString *const serviceType_AVTransport;

extern NSString *const SERVER_CALLBACK; /// 订阅回调地址
extern NSInteger const subscribeTimeout;  ///< 订阅时长 应大于50
extern NSInteger const renewSubscribeTimeout; ///< 订阅到期前要续订

