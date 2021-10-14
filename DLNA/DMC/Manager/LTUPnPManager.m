//
//  LTUPnPManager.m
//  workTools
//
//  Created by LTMAC on 2021/9/22.
//

/**
 1、参考 https://eliyar.biz/DLNA_with_iOS_Android_Part_1_Find_Device_Using_SSDP/
 2、目前没有办法做到像爱奇艺、腾讯等视频进度返回那么流畅，它们的是1s接1s返回的
 */

#import "LTUPnPManager.h"
#import "GCDWebServer.h"
#import "GCDWebServerDataRequest.h"
#import "GCDWebServerDataResponse.h"
#import "GDataXMLNode.h"

@interface LTUPnPManager ()<UPnPBrowserDelegate,UPnPPlayerDelegate,GCDWebServerDelegate>

@property (nonatomic, strong) UPnPBrowser *_Nullable upnpBrowser;
@property (nonatomic, strong) UPnPPlayer *_Nullable upnpPlayer;
@property (nonatomic, strong) UPnPAVPositionInfo *_Nullable positionInfo;
@property (nonatomic, strong) UPnPTransportInfo *_Nullable transportInfo;
@property (nonatomic, strong) GCDWebServer *_Nullable webServer;
@property (nonatomic, strong) dispatch_queue_t _Nullable subscribeQueue;
@property (nonatomic, copy) NSString *_Nullable subscribeSid;

@end

@implementation LTUPnPManager

- (instancetype)init {
    self = [super init];
    if (self) {
        [self configBasic];
    }
    return self;
}

- (void)configBasic {
    self.subscribeQueue = dispatch_queue_create("com.workTools.UPnPManager", DISPATCH_QUEUE_SERIAL);
    [self startWebServer];
}

#pragma mark -
#pragma mark - 搜索模块
- (void)bowserStartSearch {
    [self.upnpBrowser startSearch];
}

#pragma mark - UPnPBrowserDelegate
- (void)upnpBrowser:(UPnPBrowser *)browser didFindUPnPDevices:(NSArray<UPnPDevice *> *)devices {
    NSLog(@"devices:%@",devices);
    if ([self.browserDelegate respondsToSelector:@selector(upnpManager:browserDidFindUPnPDevices:)]) {
        [self.browserDelegate upnpManager:self browserDidFindUPnPDevices:devices];
    }
}

- (void)upnpBrowser:(UPnPBrowser *)browser deviceSearchError:(NSError *)error {
    NSLog(@"deviceSearch error:%@",error);
    if ([self.browserDelegate respondsToSelector:@selector(upnpManager:deviceSearchError:)]) {
        [self.browserDelegate upnpManager:self deviceSearchError:error];
    }
}

#pragma mark -
#pragma mark - 推送模块
- (void)managerPlayUrlToUPnPDevice:(UPnPDevice *)device url:(NSString *)urlString {
    [self.upnpPlayer playerUrlToUPnPDevice:device url:urlString];
}

- (void)managerPlay {
    [self.upnpPlayer play];
}

- (void)managerPause {
    [self.upnpPlayer pause];
}

- (void)managerStop {
    [self.upnpPlayer stop];
}

- (void)managerSeekToTime:(NSString *)time {
    [self.upnpPlayer seekToTime:time];
}

- (void)managerGetAVTransportInfo {
    [self.upnpPlayer getAVTransportInfo];
}

- (void)managerSubscribe {
    NSString *serverURLString = self.webServer.serverURL.absoluteString;
    if ([serverURLString hasSuffix:@"/"]) {
        serverURLString = [serverURLString substringToIndex:serverURLString.length-1];
    }
    NSString *callbackString = [NSString stringWithFormat:@"%@%@",serverURLString,SERVER_CALLBACK];
    [self.upnpPlayer sendSubscribeWithTime:subscribeTimeout callback:callbackString];
}

/// 续订
- (void)managerRenewSubscribe {
    [self.upnpPlayer sendRenewSubscribeWithSid:self.subscribeSid timeout:subscribeTimeout];
}

/// 取消订阅
- (void)managerCancelSubscribe {
    dispatch_async(self.subscribeQueue, ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(managerRenewSubscribe) object:nil];
    });
    [self.upnpPlayer sendCancelSubscribeWithSid:self.subscribeSid];
}

#pragma mark - UPnPPlayerDelegate
- (void)upnpPlayer:(UPnPPlayer *)player undefinedResponse:(NSString *)responseXml postXML:(NSString *)postXML {
    NSLog(@"%s postXML:%@",__func__,postXML);
    if ([self.playerDelegate respondsToSelector:@selector(upnpManager:undefinedResponse:postXML:)]) {
        [self.playerDelegate upnpManager:self undefinedResponse:responseXml postXML:postXML];
    }
}

- (void)upnpPlayer:(UPnPPlayer *)player errorDomain:(NSError *)error {
    NSLog(@"%s error:%@",__func__, error);
    if ([self.playerDelegate respondsToSelector:@selector(upnpManager:errorDomain:)]) {
        [self.playerDelegate upnpManager:self errorDomain:error];
    }
}

- (void)upnpPlayerAVTransportURIResponse:(UPnPPlayer *)player {
    NSLog(@"%s",__func__);
    if ([self.playerDelegate respondsToSelector:@selector(upnpManagerAVTransportURIResponse:)]) {
        [self.playerDelegate upnpManagerAVTransportURIResponse:self];
    }
    [self managerSubscribe];
}

- (void)upnpPlayerPlayResponse:(UPnPPlayer *)player {
    NSLog(@"%s",__func__);
    if ([self.playerDelegate respondsToSelector:@selector(upnpManagerPlayResponse:)]) {
        [self.playerDelegate upnpManagerPlayResponse:self];
    }
}

- (void)upnpPlayerPauseResponse:(UPnPPlayer *)player {
    NSLog(@"%s",__func__);
    if ([self.playerDelegate respondsToSelector:@selector(upnpManagerPauseResponse:)]) {
        [self.playerDelegate upnpManagerPauseResponse:self];
    }
}

- (void)upnpPlayerStopResponse:(UPnPPlayer *)player {
    NSLog(@"%s",__func__);
    if ([self.playerDelegate respondsToSelector:@selector(upnpManagerStopResponse:)]) {
        [self.playerDelegate upnpManagerStopResponse:self];
    }
}

- (void)upnpPlayerSeekResponse:(UPnPPlayer *)player {
    NSLog(@"%s",__func__);
    if ([self.playerDelegate respondsToSelector:@selector(upnpManagerSeekResponse:)]) {
        [self.playerDelegate upnpManagerSeekResponse:self];
    }
}

- (void)upnpPlayer:(UPnPPlayer *)player positionResponse:(UPnPAVPositionInfo *)position {
//    NSLog(@"position:%@",position);
    if ([self.playerDelegate respondsToSelector:@selector(upnpManager:positionResponse:)]) {
        [self.playerDelegate upnpManager:self positionResponse:position];
    }
}

- (void)upnpPlayer:(UPnPPlayer *)player transportResponse:(UPnPTransportInfo *)transport {
    NSLog(@"transport:%@",transport.CurrentTransportState);
    self.transportInfo = transport;
    if ([self.playerDelegate respondsToSelector:@selector(upnpManager:transportResponse:)]) {
        [self.playerDelegate upnpManager:self transportResponse:transport];
    }
    if ([transport.CurrentTransportState isEqualToString:@"STOPPED"]) {
        [self.upnpPlayer stopInfoTimer];
    }
}

- (void)upnpPlayer:(UPnPPlayer *)player subscribeSID:(NSString *)sid error:(NSError *)error {
    if ([self.playerDelegate respondsToSelector:@selector(upnpManager:subscribeError:)]) {
        [self.playerDelegate upnpManager:self subscribeError:error];
    }
    if (sid && error == nil) {
        self.subscribeSid = sid;
        dispatch_async(self.subscribeQueue, ^{
            [[NSObject class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(managerRenewSubscribe) object:nil];
            [self performSelector:@selector(managerRenewSubscribe) withObject:nil afterDelay:renewSubscribeTimeout];
        });
    }
}

- (void)upnpPlayer:(UPnPPlayer *)player cancelSubscribeError:(NSError *)error {
    if (error == nil) {
        self.subscribeSid = nil;
    }
}

#pragma mark -
#pragma mark - 本地服务
/// 启动本地服务器
- (void)startWebServer {
    if (self.webServer == nil) {
        self.webServer = [[GCDWebServer alloc] init];
        self.webServer.delegate = self;
        __weak typeof(self) weakSelf = self;
        [weakSelf.webServer addHandlerForMethod:@"NOTIFY" path:SERVER_CALLBACK requestClass:[GCDWebServerDataRequest class] asyncProcessBlock:^(__kindof GCDWebServerRequest *request, GCDWebServerCompletionBlock completionBlock) {
            // Do some async operation like network access or file I/O (simulated here using dispatch_after())
            GCDWebServerDataRequest *req = (GCDWebServerDataRequest *)request;
            __strong typeof(self) strongSelf = weakSelf;
            if (req.hasBody && strongSelf) {
                [strongSelf parseWebServerMessage:req.data];
            }
            GCDWebServerDataResponse* response = [GCDWebServerDataResponse responseWithHTML:@"<html><body><p>Hello World</p></body></html>"];
            if (completionBlock) {
                completionBlock(response);
            }
        }];
        [self.webServer startWithPort:8080 bonjourName:nil];
    }
}

- (void)parseWebServerMessage:(NSData *)data {
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    dataString = [self retransfer:dataString];
//    NSLog(@"dataString:%@",dataString);
    NSData *xmlData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    /**
     <e:property>
         <LastChange>
             <Event xmlns = "urn:schemas-upnp-org:metadata-1-0/AVT/">
                 <InstanceID val="0">
                     <TransportState val="PLAYING"/>
                     <TransportStatus val="OK"/>
                 </InstanceID>
             </Event>
         </LastChange>
     </e:property>
     */
    GDataXMLDocument *xmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:kNilOptions error:nil];
    GDataXMLElement *rootElement = xmlDoc.rootElement;
    NSArray *changeArray = [rootElement nodesForXPath:@"e:property/LastChange" error:nil];
    for (int m = 0; m < changeArray.count; m++) {
        GDataXMLElement *changeNode = changeArray[m];
        if ([changeNode.name isEqualToString:@"LastChange"]) {
            GDataXMLElement *eventNode = (GDataXMLElement *)[changeNode childAtIndex:0];
            GDataXMLElement *InstanceID = (GDataXMLElement *)[eventNode childAtIndex:0];
            for (int m = 0; m < InstanceID.children.count; m++) {
                GDataXMLElement *nodeEle = InstanceID.children[m];
                if ([nodeEle.name isEqualToString:@"TransportState"]) {
                    NSLog(@"TransportState value:%@", [[nodeEle attributeForName:@"val"] stringValue]);
                    self.transportInfo.CurrentTransportState = [[nodeEle attributeForName:@"val"] stringValue];
                    [self upnpPlayer:self.upnpPlayer transportResponse:self.transportInfo];
                }
            }
        }
    }
}

////有些设备返回的xml中 < > " 被转义，导致解析时候出错。所以需要先反转义，然后再解析。
- (NSString *_Nullable)retransfer:(NSString *_Nullable)string {
    if(string == nil)return nil;
    NSString*result = [string stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    result = [result stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    result = [result stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
    return result;
}

#pragma mark - GCDWebServerDelegate
- (void)webServerDidStart:(GCDWebServer *)server {
    NSLog(@"%s",__func__);
}

- (void)webServerDidStop:(GCDWebServer *)server {
    NSLog(@"%s",__func__);
}

- (void)webServerDidConnect:(GCDWebServer *)server {
    NSLog(@"%s",__func__);
}

- (void)webServerDidDisconnect:(GCDWebServer *)server {
    NSLog(@"%s",__func__);
}

#pragma mark - lazy load
- (UPnPBrowser *)upnpBrowser {
    if (_upnpBrowser) {
        return _upnpBrowser;
    }
    _upnpBrowser = [[UPnPBrowser alloc] init];
    _upnpBrowser.delegate = self;
    return _upnpBrowser;
}

- (UPnPPlayer *)upnpPlayer {
    if (_upnpPlayer) {
        return _upnpPlayer;
    }
    _upnpPlayer = [[UPnPPlayer alloc] init];
    _upnpPlayer.delegate = self;
    return _upnpPlayer;
}

@end
