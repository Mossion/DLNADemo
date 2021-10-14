//
//  UPnPProxy.h
//  workTools
//
//  Created by LTMAC on 2021/9/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UPnPProxy : NSObject

@property (nullable, nonatomic, weak, readonly) id target;

- (instancetype _Nonnull )initWithTarget:(id _Nonnull )target;

+ (instancetype _Nonnull )proxyWithTarget:(id _Nonnull )target;

@end

NS_ASSUME_NONNULL_END
