//
//  UPnPPlayer.h
//  workTools
//
//  Created by LTMAC on 2021/9/25.
//

#import <Foundation/Foundation.h>
@class UPnPDevice;
@class UPnPPlayer;
@class UPnPAVPositionInfo;
@class UPnPTransportInfo;

NS_ASSUME_NONNULL_BEGIN

@protocol UPnPPlayerDelegate <NSObject>

@optional
- (void)upnpPlayerAVTransportURIResponse:(UPnPPlayer *)player;
- (void)upnpPlayerPauseResponse:(UPnPPlayer *)player;
- (void)upnpPlayerPlayResponse:(UPnPPlayer *)player;
- (void)upnpPlayerStopResponse:(UPnPPlayer *)player;
- (void)upnpPlayerSeekResponse:(UPnPPlayer *)player;
- (void)upnpPlayer:(UPnPPlayer *)player positionResponse:(UPnPAVPositionInfo *)position;
- (void)upnpPlayer:(UPnPPlayer *)player transportResponse:(UPnPTransportInfo *)transport;

- (void)upnpPlayer:(UPnPPlayer *)player undefinedResponse:(NSString *)responseXml postXML:(NSString *)postXML;
- (void)upnpPlayer:(UPnPPlayer *)player errorDomain:(NSError *)error;

/// 订阅和续订的代理回调
/// @param sid 成功后值，续订和取消订阅需要
/// @param error 错误
- (void)upnpPlayer:(UPnPPlayer *)player subscribeSID:(NSString *_Nullable)sid error:(NSError *_Nullable)error;

/// 取消订阅
/// @param error 错误信息
- (void)upnpPlayer:(UPnPPlayer *)player cancelSubscribeError:(NSError *_Nullable)error;

@end

@interface UPnPPlayer : NSObject

@property (nonatomic,weak) id<UPnPPlayerDelegate> delegate;

/// 推送视频链接到设备
/// @param device dlna设备
/// @param urlString 网络视频链接
- (void)playerUrlToUPnPDevice:(UPnPDevice *)device url:(NSString *)urlString;

/// 播放
- (void)play;

/// 暂停
- (void)pause;

/// 结束播放
- (void)stop;

/// 设置进度
/// @param time 00:00:00样式
- (void)seekToTime:(NSString *)time;

/// 获取播放状态，在代理中回调
- (void)getAVTransportInfo;

/// 订阅事件
/// @param time 有效期
/// @param callback 回调地址
- (void)sendSubscribeWithTime:(NSInteger)time callback:(NSString *)callback;

/// 续订订阅
/// @param sid 订阅sid
/// @param time 有效期
- (void)sendRenewSubscribeWithSid:(NSString *_Nullable)sid timeout:(NSInteger)time;

/// 取消订阅
/// @param sid 订阅sid
- (void)sendCancelSubscribeWithSid:(NSString *_Nullable)sid;

/// 结束获取信息定时器
- (void)stopInfoTimer;

@end

NS_ASSUME_NONNULL_END
