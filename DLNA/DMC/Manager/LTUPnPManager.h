//
//  LTUPnPManager.h
//  workTools
//
//  Created by LTMAC on 2021/9/22.
//

#import <Foundation/Foundation.h>
#import "UPnPConst.h"
#import "UPnPBrowser.h"
#import "UPnPDevice.h"
#import "UPnPAction.h"
#import "UPnPAVPositionInfo.h"
#import "UPnPPlayer.h"
@class LTUPnPManager;

NS_ASSUME_NONNULL_BEGIN

@protocol LTUPnPManagerBrowserDelegate <NSObject>

@optional
- (void)upnpManager:(LTUPnPManager *)manager browserDidFindUPnPDevices:(NSArray<UPnPDevice *>*_Nullable)devices;

- (void)upnpManager:(LTUPnPManager *)manager deviceSearchError:(NSError *_Nullable)error;

@end

@protocol LTUPnPManagerPlayerDelegate <NSObject>

@optional
- (void)upnpManagerAVTransportURIResponse:(LTUPnPManager *)manager;
- (void)upnpManagerPauseResponse:(LTUPnPManager *)manager;
- (void)upnpManagerPlayResponse:(LTUPnPManager *)manager;
- (void)upnpManagerStopResponse:(LTUPnPManager *)manager;
- (void)upnpManagerSeekResponse:(LTUPnPManager *)manager;
- (void)upnpManager:(LTUPnPManager *)manager positionResponse:(UPnPAVPositionInfo *)position;
- (void)upnpManager:(LTUPnPManager *)manager transportResponse:(UPnPTransportInfo *)transport;
/// 订阅失败，则error不为nil
- (void)upnpManager:(LTUPnPManager *)manager subscribeError:(NSError *_Nullable)error;

- (void)upnpManager:(LTUPnPManager *)manager undefinedResponse:(NSString *)responseXml postXML:(NSString *)postXML;
- (void)upnpManager:(LTUPnPManager *)manager errorDomain:(NSError *)error;

@end

@interface LTUPnPManager : NSObject

@property (nonatomic, weak) id<LTUPnPManagerBrowserDelegate> browserDelegate;
@property (nonatomic, weak) id<LTUPnPManagerPlayerDelegate> playerDelegate;

/// 开始搜索设备
- (void)bowserStartSearch;

/// 推送视频链接到设备
/// @param device dlna设备
/// @param urlString 网络视频链接
- (void)managerPlayUrlToUPnPDevice:(UPnPDevice *)device url:(NSString *)urlString;

/// 播放
- (void)managerPlay;

/// 暂停
- (void)managerPause;

/// 结束播放
- (void)managerStop;

/// 设置进度
/// @param time 00:00:00样式
- (void)managerSeekToTime:(NSString *)time;

/// 获取播放状态，在代理中回调
- (void)managerGetAVTransportInfo;

/// 订阅事件
- (void)managerSubscribe;

/// 取消订阅
- (void)managerCancelSubscribe;

@end

NS_ASSUME_NONNULL_END
