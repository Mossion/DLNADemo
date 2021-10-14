//
//  UPnPAction.m
//  workTools
//
//  Created by LTMAC on 2021/9/27.
//

#import "UPnPAction.h"
#import "GDataXMLNode.h"
#import "UPnPConst.h"
#import "UPnPDevice.h"

@interface UPnPAction ()

@property (nonatomic, strong) GDataXMLElement *_Nullable xmlElement;
@property (nonatomic, copy) NSString *_Nullable action;

@end

@implementation UPnPAction

- (instancetype)initWithAction:(NSString *)aciton {
    self = [super init];
    if (self) {
        self.action = aciton;
        self.serviceType = UPnPServiceTypeAVTransport;
        NSString *name = [NSString stringWithFormat:@"u:%@",aciton];
        self.xmlElement = [GDataXMLElement elementWithName:name];
    }
    return self;
}

- (void)setArgumentValue:(NSString *)value forName:(NSString *)name {
    [self.xmlElement addChild:[GDataXMLElement elementWithName:name stringValue:value]];
}

- (void)setAttributeValue:(NSString *)value forName:(NSString *)name {
    [self.xmlElement addChild:[GDataXMLElement attributeWithName:name stringValue:value]];
}

- (void)setServiceType:(UPnPServiceType)serviceType {
    _serviceType = serviceType;
}

- (NSString *)getServiceType {
    if (_serviceType == UPnPServiceTypeAVTransport) {
        return serviceType_AVTransport;
    } else {
        return serviceType_RenderingControl;
    }
}

- (NSString *)getPostUrlWithDevice:(UPnPDevice *)device {
    if (self.serviceType == UPnPServiceTypeAVTransport) {
        return [self getUPnPUrlWithServiceModel:device.AVTransportService urlHeader:device.httpString];
    } else {
        return [self getUPnPUrlWithServiceModel:device.RenderingService urlHeader:device.httpString];
    }
}

- (NSString *)getUPnPUrlWithServiceModel:(UPnPService *)service urlHeader:(NSString *)urlHeader {
    NSString *urlString;
    if ([service.controlURL hasPrefix:@"/"]) {
        urlString = [NSString stringWithFormat:@"%@%@",urlHeader,service.controlURL];
    } else {
        urlString = [NSString stringWithFormat:@"%@/%@",urlHeader,service.controlURL];
    }
    return urlString;
}

- (NSString *)getSOAPAction {
    if (_serviceType == UPnPServiceTypeAVTransport) {
        return [NSString stringWithFormat:@"\"%@#%@\"",serviceType_AVTransport,self.action];
    } else {
        return [NSString stringWithFormat:@"\"%@#%@\"",serviceType_RenderingControl,self.action];
    }
}

- (NSString *)getPostXMLFile {
    GDataXMLElement *xmlEle = [GDataXMLElement elementWithName:@"s:Envelope"];
    [xmlEle addChild:[GDataXMLElement attributeWithName:@"s:encodingStyle" stringValue:@"http://schemas.xmlsoap.org/soap/encoding/"]];
    [xmlEle addChild:[GDataXMLElement attributeWithName:@"xmlns:s" stringValue:@"http://schemas.xmlsoap.org/soap/envelope/"]];
    if (_serviceType == UPnPServiceTypeAVTransport) {
        [xmlEle addChild:[GDataXMLElement attributeWithName:@"xmlns:u" stringValue:serviceType_AVTransport]];  // 操作指令，需要加这个参数
    }
    GDataXMLElement *bodyEle = [GDataXMLElement elementWithName:@"s:Body"];
    [bodyEle addChild:self.xmlElement];
    [xmlEle addChild:bodyEle];
    return xmlEle.XMLString;
}

@end
