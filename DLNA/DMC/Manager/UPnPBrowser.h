//
//  UPnPBrowser.h
//  workTools
//
//  Created by LTMAC on 2021/9/22.
//

#import <Foundation/Foundation.h>
@class UPnPDevice;
@class UPnPBrowser;

NS_ASSUME_NONNULL_BEGIN

@protocol UPnPBrowserDelegate <NSObject>

@optional
- (void)upnpBrowser:(UPnPBrowser *)browser didFindUPnPDevices:(NSArray<UPnPDevice *> *_Nullable)devices;

- (void)upnpBrowser:(UPnPBrowser *)browser deviceSearchError:(NSError *_Nullable)error;

@end

@interface UPnPBrowser : NSObject

@property (nonatomic,weak) id<UPnPBrowserDelegate> delegate;

- (void)startSearch;

@end

NS_ASSUME_NONNULL_END
