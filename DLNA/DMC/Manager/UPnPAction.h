//
//  UPnPAction.h
//  workTools
//
//  Created by LTMAC on 2021/9/27.
//

#import <Foundation/Foundation.h>
@class UPnPDevice;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, UPnPServiceType) {
    UPnPServiceTypeAVTransport,  ///<  urn:schemas-upnp-org:service:AVTransport:1
    UPnPServiceTypeRenderingControl, /// <  urn:schemas-upnp-org:service:RenderingControl:1
};

@interface UPnPAction : NSObject

- (instancetype)initWithAction:(NSString *)aciton;

@property (nonatomic, assign) UPnPServiceType serviceType;

- (void)setArgumentValue:(NSString *)value forName:(NSString *)name;

- (void)setAttributeValue:(NSString *)value forName:(NSString *)name;

- (NSString *)getPostUrlWithDevice:(UPnPDevice *)device;

- (NSString *)getSOAPAction;

- (NSString *)getPostXMLFile;

@end

NS_ASSUME_NONNULL_END
