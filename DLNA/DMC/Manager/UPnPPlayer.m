//
//  UPnPPlayer.m
//  workTools
//
//  Created by LTMAC on 2021/9/25.
//

/**
 注意：
 1、如果在推送的时候请求头设置了 User-Agent， 那么在其他操作的时候，也应该设置User-Agent
     乐播apk的User-Agent:  UPnP/1.0 LEBODLNA/lebolna/NewDLNA/1.0
 2、推送视频，需要在 SetAVTransportURI 节点上添加属性 xmlns:u，其值为 urn:schemas-upnp-org:service:AVTransport:1
 3、恢复播放，必需要添加节点 Speed。 暂停可不设置
 4、续订请求头里，只需 SID 和 TIMEOUT 两个参数即可。
 5、取消订阅，请求头只需 SID 一个参数即可。
 */


#import "UPnPPlayer.h"
#import "UPnPDevice.h"
#import "UPnPAction.h"
#import "UPnPAVPositionInfo.h"
#import "UPnPConst.h"
#import "UPnPProxy.h"
#import "GDataXMLNode.h"
#import <UIKit/UIKit.h>

@interface UPnPPlayer ()

@property (nonatomic, strong) UPnPDevice *_Nullable device;
@property (nonatomic, copy) NSString *_Nullable videoUrl;
@property (nonatomic, strong) NSTimer *_Nullable infoTimer;

@end

@implementation UPnPPlayer

- (void)playerUrlToUPnPDevice:(UPnPDevice *)device url:(NSString *)urlString {
    NSLog(@"device:%@",device);
    self.device = device;
    self.videoUrl = urlString;
    [self upnpActionRequest];
}

/// 推送视频
- (void)upnpActionRequest {
    UPnPAction *action = [[UPnPAction alloc] initWithAction:@"SetAVTransportURI"];
    [action setAttributeValue:serviceType_AVTransport forName:@"xmlns:u"];  /// < 某些设备需要加此数据
    [action setArgumentValue:@"0" forName:@"InstanceID"];
    [action setArgumentValue:self.videoUrl forName:@"CurrentURI"];
    [action setArgumentValue:@"" forName:@"CurrentURIMetaData"];
    [self postRequest:action];
}

- (void)play {
    UPnPAction *action = [[UPnPAction alloc] initWithAction:@"Play"];
    [action setArgumentValue:@"0" forName:@"InstanceID"];
    [action setArgumentValue:@"2" forName:@"Speed"]; // 恢复必要传此参数
    [self postRequest:action];
}

- (void)pause {
    UPnPAction *action = [[UPnPAction alloc] initWithAction:@"Pause"];
    [action setArgumentValue:@"0" forName:@"InstanceID"];
    [self postRequest:action];
}

- (void)stop {
    UPnPAction *action = [[UPnPAction alloc] initWithAction:@"Stop"];
    [action setArgumentValue:@"0" forName:@"InstanceID"];
    [self postRequest:action];
}

- (void)getPositionInfo {
    UPnPAction *action = [[UPnPAction alloc]  initWithAction:@"GetPositionInfo"];
    [action setArgumentValue:@"0" forName:@"InstanceID"];
    [self postRequest:action];
}

- (void)getAVTransportInfo {
    UPnPAction *action = [[UPnPAction alloc] initWithAction:@"GetTransportInfo"];
    [action setArgumentValue:@"0" forName:@"InstanceID"];
    [self postRequest:action];
}

- (void)seekToTime:(NSString *)time {
    UPnPAction *action = [[UPnPAction alloc] initWithAction:@"Seek"];
    [action setArgumentValue:@"0" forName:@"InstanceID"];
    [action setArgumentValue:@"REL_TIME" forName:@"Unit"];
    [action setArgumentValue:time forName:@"Target"];
    [self postRequest:action];
}

- (void)startPlayInfoTimer{
    [self stopInfoTimer];
    self.infoTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:[UPnPProxy proxyWithTarget:self] selector:@selector(getPlayInfo) userInfo:nil repeats:YES];
    [self.infoTimer fire];
}

- (void)stopInfoTimer{
    if (_infoTimer != nil) {
        [_infoTimer invalidate];
        self.infoTimer = nil;
    }
}

/// 获取播放进度信息
- (void)getPlayInfo {
    [self getPositionInfo];
}

- (void)postRequest:(UPnPAction *)action {
    NSString *soapAction = [action getSOAPAction];
    NSString *xmlString = [action getPostXMLFile];
    NSURL *url = [NSURL URLWithString:[action getPostUrlWithDevice:self.device]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"text/xml; charset=\"utf-8\"" forHTTPHeaderField:@"Content-Type"];
    [request setValue:soapAction forHTTPHeaderField:@"SOAPACTION"];
    request.HTTPBody = [xmlString dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 3;
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error == nil && data) {
                [self handlePlayActionResponseData:data postXML:xmlString];
            } else {
                [self undefinedResponse:nil postXML:xmlString];
                if([error.userInfo.allKeys containsObject:@"NSUnderlyingError"]){
                    NSString *errorStr = [NSString stringWithFormat:@"%@",error.userInfo[@"NSUnderlyingError"]];
                    if([errorStr containsString:@"kCFErrorDomainCFNetwork"]){
                        [self errorDomain:error];
                    }
                }
            }
        });
    }] resume];
}

- (void)handlePlayActionResponseData:(NSData *)data postXML:(NSString *)xmlString {
    GDataXMLDocument *xmlDoc = [[GDataXMLDocument alloc] initWithData:data options:kNilOptions error:nil];
    GDataXMLElement *rootElement = xmlDoc.rootElement;
    NSArray *rootChildren = rootElement.children;
    for (int i = 0; i < rootChildren.count; i++) {
        GDataXMLElement *node = rootChildren[i];
        NSArray *nodeArray = node.children;
        if ([node.name isEqualToString:@"s:Body"]) {
            [self resolveResponse:nodeArray postXML:xmlString];
        }
    }
}

- (void)resolveResponse:(NSArray *)nodeArray postXML:(NSString *)postXML {
    for (int m = 0; m < nodeArray.count; m++) {
        GDataXMLElement *element = nodeArray[m];
        if ([element.name hasSuffix:@"SetAVTransportURIResponse"]) {
            [self playerSetAVTransportURIResponse];
            // 启动定时器，获取播放信息
            [self startPlayInfoTimer];
        } else if ([element.name hasSuffix:@"PauseResponse"]) {
            [self playerPauseResponse];
        } else if ([element.name hasSuffix:@"PlayResponse"]) {
            [self playerPlayResponse];
        } else if ([element.name hasSuffix:@"StopResponse"]) {
            [self playerStopResponse];
            [self stopInfoTimer];
        } else if ([element.name hasSuffix:@"GetPositionInfoResponse"]) {
            NSArray *positionArray = element.children;
            [self playerPositionResponse:positionArray];
        } else if ([element.name hasSuffix:@"GetTransportInfoResponse"]) {
            NSArray *transportArray = element.children;
            [self playerTransfortResponse:transportArray];
        } else {
            NSString *xmlString = element.XMLString;
            [self undefinedResponse:xmlString postXML:postXML];
        }
    }
}

#pragma mark - 各种指令回调
- (void)playerSetAVTransportURIResponse {
    if ([self.delegate respondsToSelector:@selector(upnpPlayerAVTransportURIResponse:)]) {
        [self.delegate upnpPlayerAVTransportURIResponse:self];
    }
}

- (void)playerPauseResponse {
    if ([self.delegate respondsToSelector:@selector(upnpPlayerPauseResponse:)]) {
        [self.delegate upnpPlayerPauseResponse:self];
    }
}

- (void)playerPlayResponse {
    if ([self.delegate respondsToSelector:@selector(upnpPlayerPlayResponse:)]) {
        [self.delegate upnpPlayerPlayResponse:self];
    }
}

- (void)playerStopResponse {
    if ([self.delegate respondsToSelector:@selector(upnpPlayerStopResponse:)]) {
        [self.delegate upnpPlayerStopResponse:self];
    }
}

- (void)playerSeekResponse {
    if ([self.delegate respondsToSelector:@selector(upnpPlayerSeekResponse:)]) {
        [self.delegate upnpPlayerSeekResponse:self];
    }
}

- (void)playerPositionResponse:(NSArray *)array {
    UPnPAVPositionInfo *postionInfo = [[UPnPAVPositionInfo alloc] init];
    [postionInfo setArray:array];
    if ([self.delegate respondsToSelector:@selector(upnpPlayer:positionResponse:)]) {
        [self.delegate upnpPlayer:self positionResponse:postionInfo];
    }
}

- (void)playerTransfortResponse:(NSArray *)array {
    UPnPTransportInfo *transportInfo = [[UPnPTransportInfo alloc] init];
    [transportInfo setArray:array];
    if ([self.delegate respondsToSelector:@selector(upnpPlayer:transportResponse:)]) {
        [self.delegate upnpPlayer:self transportResponse:transportInfo];
    }
}

- (void)undefinedResponse:(NSString *)xmlString postXML:(NSString *)postXML {
    if ([self.delegate respondsToSelector:@selector(upnpPlayer:undefinedResponse:postXML:)]) {
        [self.delegate upnpPlayer:self undefinedResponse:xmlString postXML:postXML];
    }
}

- (void)errorDomain:(NSError *)error {
    if([self.delegate respondsToSelector:@selector(upnpPlayer:errorDomain:)]){
        [self.delegate upnpPlayer:self errorDomain:error];
    }
}

#pragma mark - 订阅
- (void)sendSubscribeWithTime:(NSInteger)time callback:(nonnull NSString *)callback{
    NSString *callbackString = [NSString stringWithFormat:@"<%@>",callback];
    NSString *userAgent = [NSString stringWithFormat:@"iOS/%@ UPnP/1.1 SCDLNA/1.0",[UIDevice currentDevice].systemVersion];
    NSString *timeout = [NSString stringWithFormat:@"Second-%ld",time];
    NSMutableDictionary *headerField = [[NSMutableDictionary alloc] init];
    [headerField setValue:callbackString forKey:@"CALLBACK"];
    [headerField setValue:userAgent forKey:@"USER-AGENT"];
    [headerField setValue:@"upnp:event" forKey:@"NT"];
    [headerField setValue:timeout forKey:@"TIMEOUT"];
    __weak typeof(self) weakself = self;
    [self subscribeActionRequestMethod:@"SUBSCRIBE" headerFiled:headerField callback:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(self) strongself = weakself;
        if (error == nil) {
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"dataString:%@",dataString);
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSInteger httpStatus = httpResponse.statusCode;
            if (httpStatus == 200) {
                NSString *sid = httpResponse.allHeaderFields[@"SID"];
                if ([strongself.delegate respondsToSelector:@selector(upnpPlayer:subscribeSID:error:)]) {
                    [strongself.delegate upnpPlayer:self subscribeSID:sid error:nil];
                }
                return;
            }
            error = [NSError errorWithDomain:@"UPnPPlayer.domain" code:999 userInfo:@{@"userInfo":@"订阅失败"}];
        }
        if ([strongself.delegate respondsToSelector:@selector(upnpPlayer:subscribeSID:error:)]) {
            [strongself.delegate upnpPlayer:self subscribeSID:nil error:error];
        }
    }];
}

- (void)sendRenewSubscribeWithSid:(NSString *_Nullable)sid timeout:(NSInteger)time {
    NSString *timeout = [NSString stringWithFormat:@"Second-%ld",time];
    NSMutableDictionary *headerField = [[NSMutableDictionary alloc] init];
    [headerField setValue:timeout forKey:@"TIMEOUT"];
    [headerField setValue:sid forKey:@"SID"];
    __weak typeof(self) weakself = self;
    [self subscribeActionRequestMethod:@"SUBSCRIBE" headerFiled:headerField callback:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"sendRenewSubscribeWithSid data:%@ response:%@ error:%@", data, response, error);
        if (error == nil) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSInteger httpStatus = httpResponse.statusCode;
            if (httpStatus == 200) {
                NSString *sid = httpResponse.allHeaderFields[@"SID"];
                if ([weakself.delegate respondsToSelector:@selector(upnpPlayer:subscribeSID:error:)]) {
                    [weakself.delegate upnpPlayer:self subscribeSID:sid error:nil];
                }
                return;
            }
            error = [NSError errorWithDomain:@"UPnPPlayer.domain" code:999 userInfo:@{@"userInfo":@"续订失败"}];
        }
        if ([weakself.delegate respondsToSelector:@selector(upnpPlayer:subscribeSID:error:)]) {
            [weakself.delegate upnpPlayer:self subscribeSID:nil error:error];
        }
    }];
}

- (void)sendCancelSubscribeWithSid:(NSString *_Nullable)sid {
    NSMutableDictionary *headerField = [[NSMutableDictionary alloc] init];
    [headerField setValue:sid forKey:@"SID"];
    __weak typeof(self) weakself = self;
    [self subscribeActionRequestMethod:@"UNSUBSCRIBE" headerFiled:headerField callback:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"sendCancelSubscribeWithSid data:%@ response:%@ error:%@", data, response, error);
        if (error == nil) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSInteger httpStatus = httpResponse.statusCode;
            if (httpStatus == 200) {
                if ([weakself.delegate respondsToSelector:@selector(upnpPlayer:cancelSubscribeError:)]) {
                    [weakself.delegate upnpPlayer:self cancelSubscribeError:nil];
                }
                return;
            }
            error = [NSError errorWithDomain:@"UPnPPlayer.domain" code:999 userInfo:@{@"userInfo":@"取消订阅失败"}];
        }
        if ([weakself.delegate respondsToSelector:@selector(upnpPlayer:cancelSubscribeError:)]) {
            [weakself.delegate upnpPlayer:self cancelSubscribeError:error];
        }
    }];
}

- (void)subscribeActionRequestMethod:(NSString *_Nullable)method headerFiled:(NSDictionary *_Nullable)headerField callback:(void(^)(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error))callback {
    NSString *urlString = [NSString stringWithFormat:@"%@/%@",self.device.httpString,self.device.AVTransportService.eventSubURL];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.allHTTPHeaderFields = headerField;
    request.HTTPMethod = method;
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (callback) {
            callback(data, response, error);
        }
    }] resume];
}

@end
