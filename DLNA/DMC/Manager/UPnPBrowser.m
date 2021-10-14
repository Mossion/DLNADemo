//
//  UPnPBrowser.m
//  workTools
//
//  Created by LTMAC on 2021/9/22.
//

#import "UPnPBrowser.h"
//#import "LEBAsyncUdpSocket.h"
#import "GCDAsyncUdpSocket.h"
#import "UPnPConst.h"
#import "UPnPDevice.h"
#import "GDataXMLNode.h"

typedef NS_ENUM(NSUInteger, DictOperateType) {
    OperateTypeAdd,
    OperateTypeRemove,
    OperateTypeRemoveALL,
    OperateTypeAllValues,
};

@interface UPnPBrowser ()<GCDAsyncUdpSocketDelegate>

@property (nonatomic, strong) GCDAsyncUdpSocket *_Nullable udpSocket;
@property (nonatomic, strong) dispatch_queue_t _Nullable udpQueue;
/// 保存设备 key: device's usn  value: device
@property (nonatomic, strong) NSMutableDictionary *_Nullable deviceDictionary;
@property (nonatomic, strong) NSTimer *_Nullable searchTimer; //搜索定时器

@end

@implementation UPnPBrowser

- (instancetype)init {
    self = [super init];
    if (self) {
        [self configBasic];
    }
    return self;
}

- (void)configBasic {
    self.udpQueue = dispatch_queue_create("com.workTools.DMR.upnp.discover", DISPATCH_QUEUE_SERIAL);
    self.deviceDictionary = [[NSMutableDictionary alloc] init];
    self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:self.udpQueue];
}

- (void)startSearch {
    NSError *error = nil;
    if ([self.udpSocket isClosed] == NO) {
        [self handleSearch];
        return;
    }
    // 重置重用端口，否则会被其他的DLNA影响
    [self.udpSocket enableReusePort:YES error:&error];
    if ([self.udpSocket bindToPort:ssdpPort error:&error] == NO) {
        NSLog(@"bindPort error:%@",error);
        [self searchError:error];
        return;
    }
    if ([self.udpSocket beginReceiving:&error] == NO) {
        NSLog(@"beginReceiving error:%@",error);
        [self searchError:error];
        return;
    }
    if ([self.udpSocket joinMulticastGroup:ssdpAddress error:&error] == NO) {
        NSLog(@"joinMulticastGroup error:%@",error);
        [self searchError:error];
        return;
    }
    [self handleSearch];
    [self startTimerSearch];
}

- (void)handleSearch {
    /**
    一般情况我们使用多播搜索消息来搜索所有设备即可。多播搜索消息如下：

    M-SEARCH * HTTP/1.1             // 请求头 不可改变
    MAN: "ssdp:discover"            // 设置协议查询的类型，必须是：ssdp:discover
    MX: 5                           // 设置设备响应最长等待时间，设备响应在0和这个值之间随机选择响应延迟的值。这样可以为控制点响应平衡网络负载。
    HOST: 239.255.255.250:1900      // 设置为协议保留多播地址和端口，必须是：239.255.255.250:1900（IPv4）或FF0x::C(IPv6
    ST: upnp:rootdevice             // 设置服务查询的目标，它必须是下面的类型：
                                    // ssdp:all  搜索所有设备和服务
                                    // upnp:rootdevice  仅搜索网络中的根设备
                                    // uuid:device-UUID  查询UUID标识的设备
                                    // urn:schemas-upnp-org:device:device-Type:version  查询device-Type字段指定的设备类型，设备类型和版本由UPNP组织定义。
                                    // urn:schemas-upnp-org:service:service-Type:version  查询service-Type字段指定的服务类型，服务类型和版本由UPNP组织定义。
    如果需要实现投屏，则设备类型 ST 为 urn:schemas-upnp-org:service:AVTransport:1
     */
    NSData *sendData = [[self getSearchString] dataUsingEncoding:NSUTF8StringEncoding];
    [self.udpSocket sendData:sendData toHost:ssdpAddress port:ssdpPort withTimeout:-1 tag:100];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSData *renderData = [[self getMediaRendererString] dataUsingEncoding:NSUTF8StringEncoding];
        [self.udpSocket sendData:renderData toHost:ssdpAddress port:ssdpPort withTimeout:-1 tag:200];
    });
}

- (void)searchTimerSel {
    NSData *sendData = [[self getSearchString] dataUsingEncoding:NSUTF8StringEncoding];
    [self.udpSocket sendData:sendData toHost:ssdpAddress port:ssdpPort withTimeout:-1 tag:1];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSData *renderData = [[self getMediaRendererString] dataUsingEncoding:NSUTF8StringEncoding];
        [self.udpSocket sendData:renderData toHost:ssdpAddress port:ssdpPort withTimeout:-1 tag:2];
    });
}

- (void)startTimerSearch {
    [self stopTimerSearch];
    NSTimeInterval interval = 10;
    self.searchTimer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(searchTimerSel) userInfo:nil repeats:YES];
    [self.searchTimer fire];
}

- (void)stopTimerSearch {
    if (self.searchTimer) {
        [self.searchTimer invalidate];
        self.searchTimer = nil;
    }
}

- (NSString *)getSearchString {
    return [NSString stringWithFormat:@"M-SEARCH * HTTP/1.1\r\nMAN:\"ssdp:discover\"\r\nMX:15\r\nHOST:%@:%d\r\nST: upnp:rootdevice",ssdpAddress,ssdpPort];
}

- (NSString *)getMediaRendererString {
    return [NSString stringWithFormat:@"M-SEARCH * HTTP/1.1\r\nMAN:\"ssdp:discover\"\r\nMX:15\r\nHOST:%@:%d\r\nST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n\r\n",ssdpAddress,ssdpPort];
}

- (void)handleReceiveData:(NSData *)data {
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([dataString hasPrefix:@"NOTIFY"]) {
        [self handleNotifyString:dataString];
    } else if ([dataString hasPrefix:@"HTTP/1.1"]) {
        [self handleHttpString:dataString];
    }
}

/// 主动通知方式
/// @param notifyString ssdp:alive(设备可用) 和 ssdp:byebye(设备不可用)
- (void)handleNotifyString:(NSString *)notifyString {
    /**
    当设备添加到网络后，定期向（239.255.255.250:1900）发送SSDP通知消息宣告自己的设备和服务。

    宣告消息分为 ssdp:alive(设备可用) 和 ssdp:byebye(设备不可用)

    ssdp:alive 消息
    NOTIFY * HTTP/1.1           // 消息头
    NT:                         // 在此消息中，NT头必须为服务的服务类型。（如：upnp:rootdevice）
    HOST:                       // 设置为协议保留多播地址和端口，必须是：239.255.255.250:1900（IPv4）或FF0x::C(IPv6
    NTS:                        // 表示通知消息的子类型，必须为ssdp:alive
    LOCATION:                   // 包含根设备描述得URL地址  device 的webservice路径（如：http://127.0.0.1:2351/1.xml)
    CACHE-CONTROL:              // max-age指定通知消息存活时间，如果超过此时间间隔，控制点可以认为设备不存在 （如：max-age=1800）
    SERVER:                     // 包含操作系统名，版本，产品名和产品版本信息( 如：Windows NT/5.0, UPnP/1.0)
    USN:                        // 表示不同服务的统一服务名，它提供了一种标识出相同类型服务的能力。如：
                                // 根/启动设备 uuid:f7001351-cf4f-4edd-b3df-4b04792d0e8a::upnp:rootdevice
                                // 连接管理器  uuid:f7001351-cf4f-4edd-b3df-4b04792d0e8a::urn:schemas-upnp-org:service:ConnectionManager:1
                                // 内容管理器 uuid:f7001351-cf4f-4edd-b3df-4b04792d0e8a::urn:schemas-upnp-org:service:ContentDirectory:1
    ssdp:byebye 消息
    当设备即将从网络中退出时，设备需要对每一个未超期的 ssdp:alive 消息多播形式发送 ssdp:byebye 消息，其格式如下：

    NOTIFY * HTTP/1.1       // 消息头
    HOST:                   // 设置为协议保留多播地址和端口，必须是：239.255.255.250:1900（IPv4）或FF0x::C(IPv6
    NTS:                    // 表示通知消息的子类型，必须为ssdp:byebye
    USN:                    // 同上
     */
    NSString *notiString = notifyString;
    NSString *nt = [self headerValueForKey:@"NT" inData:notiString];
    if ([nt isEqualToString:serviceType_AVTransport]) {
        NSString *nts = [self headerValueForKey:@"NTS" inData:notiString];
        NSString *location = [self headerValueForKey:@"LOCATION" inData:notiString];
        NSString *usn = [self headerValueForKey:@"USN" inData:notiString];
        if ([nts isEqualToString:@"ssdp:alive"]) {
            if (location == nil) {
                return;
            }
            dispatch_async(self.udpQueue, ^{
                if ([self.deviceDictionary objectForKey:usn] == nil) {
                    UPnPDevice *device = [self getDeviceDescribeWithLocation:location usn:usn];
                    [self addDevice:device key:usn];
                }
            });
        } else {
            dispatch_async(self.udpQueue, ^{
                [self removeDeviceWithKey:usn];
            });
        }
    }
}

/// 多播搜索响应
- (void)handleHttpString:(NSString *)httpString {
    /**
    多播搜索响应
    多播搜索 M-SEARCH 响应与通知消息很类此，只是将NT字段作为ST字段。响应必须以一下格式发送：

    HTTP/1.1 200 OK             // * 消息头
    LOCATION:                   // * 包含根设备描述得URL地址  device 的webservice路径（如：http://127.0.0.1:2351/1.xml)
    CACHE-CONTROL:              // * max-age指定通知消息存活时间，如果超过此时间间隔，控制点可以认为设备不存在 （如：max-age=1800）
    SERVER:                     // 包含操作系统名，版本，产品名和产品版本信息( 如：Windows NT/5.0, UPnP/1.0)
    EXT:                        // 为了符合HTTP协议要求，并未使用。
    BOOTID.UPNP.ORG:            // 可以不存在，初始值为时间戳，每当设备重启并加入到网络时+1，用于判断设备是否重启。也可以用于区分多宿主设备。
    CONFIGID.UPNP.ORG:          // 可以不存在，由两部分组成的非负十六进制整数，由两部分组成，第一部分代表跟设备和其上的嵌入式设备，第二部分代表这些设备上的服务。
    USN:                        // * 表示不同服务的统一服务名
    ST:                         // * 服务的服务类型
    DATE:                       // 响应生成时间
    其中主要关注带有 * 的部分即可。这里还有一个大坑，有些设备返回来的字段名称可能包含有小写，如LOCATION和Location，需要做处理。
    此外还需根据LOCATION保存设备的IP和端口地址。
     */
    
    NSString *nt = [self headerValueForKey:@"NT" inData:httpString];
    if ([nt isEqualToString:serviceType_AVTransport]) {
        NSString *nts = [self headerValueForKey:@"NTS" inData:httpString];
        NSString *location = [self headerValueForKey:@"LOCATION" inData:httpString];
        NSString *usn = [self headerValueForKey:@"USN" inData:httpString];
        if ([nts isEqualToString:@"ssdp:alive"]) {
            if (location == nil) {
                return;
            }
            dispatch_async(self.udpQueue, ^{
                if ([self.deviceDictionary objectForKey:usn] == nil) {
                    UPnPDevice *device = [self getDeviceDescribeWithLocation:location usn:usn];
                    [self addDevice:device key:usn];
                }
            });
        }
    }
}

- (UPnPDevice *)getDeviceDescribeWithLocation:(NSString *)location usn:(NSString *)usn {
    dispatch_semaphore_t seamphore = dispatch_semaphore_create(0);
    __block UPnPDevice *device = nil;
    NSURL *url = [NSURL URLWithString:location];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];
    request.HTTPMethod = @"GET";
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            return;
        }
        if (data == nil || response == nil) {
            return;
        }
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (httpResponse.statusCode == 200) {
            GDataXMLDocument *xmlDoc = [[GDataXMLDocument alloc] initWithData:data options:kNilOptions error:nil];
            GDataXMLElement *rootElement = xmlDoc.rootElement;
            NSArray *children = rootElement.children;
            device = [[UPnPDevice alloc] init];
            device.location = location;
            device.uuid = usn;
            for (int m = 0; m < children.count; m++) {
                GDataXMLNode *ele = children[m];
                if ([ele.name isEqualToString:@"device"]) {
                    NSArray *deviceInfoArray = ele.children;
                    [device setArray:deviceInfoArray];
                    break;
                }
            }
        }
        dispatch_semaphore_signal(seamphore);
    }] resume];
    dispatch_semaphore_wait(seamphore, DISPATCH_TIME_FOREVER);
    return device;
}

- (NSString *)headerValueForKey:(NSString *)key inData:(NSString *)data {
    @synchronized (self) {
        NSString *returnString;
        NSArray *valueArray = [data componentsSeparatedByString:@"\r\n"];
        for (NSString *valueString in valueArray) {
            NSString *separateString = @": ";
            NSRange range = [valueString rangeOfString:separateString];
            if ([valueString containsString:separateString] && valueString.length >= range.location + range.length + 1) {
                NSString *dictKeyString = [[valueString substringWithRange:NSMakeRange(0, range.location)] uppercaseString]; //key 切换成大写
                NSString *dictValueString = [valueString substringFromIndex:range.location+range.length];
                if ([dictKeyString isEqualToString:key]) {
                    returnString = dictValueString;
                    break;
                }
            }
        }
        return returnString;
    }
}

- (UPnPDevice *)handleDeviceInfoWithData:(NSData *)data location:(NSString *)location usn:(NSString *)usn {
    GDataXMLDocument *xmlDoc = [[GDataXMLDocument alloc] initWithData:data options:kNilOptions error:nil];
    GDataXMLElement *rootElement = xmlDoc.rootElement;
    NSArray *children = rootElement.children;
    UPnPDevice *device = [[UPnPDevice alloc] init];
    device.location = location;
    device.uuid = usn;
    for (int m = 0; m < children.count; m++) {
        GDataXMLNode *ele = children[m];
        if ([ele.name isEqualToString:@"device"]) {
            NSArray *deviceInfoArray = ele.children;
            [device setArray:deviceInfoArray];
            break;
        }
    }
    return device;
}

/// 操作deviceDictionary
/// @param dictionary 数据
/// @param operateType 类型
/// @param object 数据
/// @param key 数据
- (NSArray *)operateDictionary:(NSMutableDictionary *)dictionary operateType:(DictOperateType)operateType object:(id)object key:(NSString *)key {
    // 需要加锁，防止不同线程处理同一个数据导致的崩溃
    @synchronized (self) {
        if (dictionary == nil) {
            return nil;
        }
        switch (operateType) {
            case OperateTypeAdd: {
                if (object && key) {
                    [dictionary setValue:object forKey:key];
                }
            }
                break;
            case OperateTypeRemove: {
                if (key) {
                    [dictionary removeObjectForKey:key];
                }
            }
                break;
            case OperateTypeRemoveALL: {
                [dictionary removeAllObjects];
            }
                break;
            case OperateTypeAllValues: {
                return dictionary.allValues;
            }
                break;
            default:
                break;
        }
        return nil;
    }
}


- (void)addDevice:(UPnPDevice *)device key:(NSString *)key {
    if (device && key) {
        [self.deviceDictionary setObject:device forKey:key];
        [self devicesListDidChange];
    }
}

- (void)removeDeviceWithKey:(NSString *)key {
    if (key == nil) {
        return;
    }
    [self operateDictionary:self.deviceDictionary operateType:OperateTypeRemove object:nil key:key];
    [self devicesListDidChange];
}

- (void)devicesListDidChange {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *devices = [self operateDictionary:self.deviceDictionary operateType:OperateTypeAllValues object:nil key:nil];
        if ([self.delegate respondsToSelector:@selector(upnpBrowser:didFindUPnPDevices:)]) {
            [self.delegate upnpBrowser:self didFindUPnPDevices:devices];
        }
    });
}

- (void)searchError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(upnpBrowser:deviceSearchError:)]) {
        [self.delegate upnpBrowser:self deviceSearchError:error];
    }
}

#pragma mark -
#pragma mark - GCDAsyncUdpSocketDelegate
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    NSLog(@"%s socket:%@  tag:%ld",__func__,sock,tag);
//    NSError *error = NULL;
//    /// 开始接受数据
//    [self.udpSocket beginReceiving:&error];
//    if (error) {
//        NSLog(@"%@ tag:%ld 接受数据失败：%@",sock,tag,error);
//    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error {
    NSLog(@"%s socket:%@  tag:%ld error:%@",__func__,sock,tag,error);
    [self searchError:error];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address {
    NSString *addressString = [[NSString alloc] initWithData:address encoding:NSUTF8StringEncoding];
    NSLog(@"%s socket:%@ address:%@",__func__,sock,addressString);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(nullable id)filterContext {
//    NSString *addressString = [[NSString alloc] initWithData:address encoding:NSUTF8StringEncoding];
//    NSLog(@"%s  sock:%@  address:%@",__func__,sock,addressString);
    [self handleReceiveData:data];
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError  * _Nullable)error {
    NSLog(@"%s sock:%@ error:%@",__func__,sock,error);
    [self searchError:error];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError * _Nullable)error {
    NSLog(@"%s",__func__);
    [self searchError:error];
}

@end
