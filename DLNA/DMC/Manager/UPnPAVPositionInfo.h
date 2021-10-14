//
//  UPnPAVPositionInfo.h
//  workTools
//
//  Created by LTMAC on 2021/9/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UPnPAVPositionInfo : NSObject

@property (nonatomic, assign) float relTime;   ///< 当前播放时间
@property (nonatomic, assign) float absTime;  ///< 当前播放时间
@property (nonatomic, assign) float duration;  ///< 总时长
@property (nonatomic, assign) float progress; ///<  0~1

@property (nonatomic, copy) NSString *_Nullable relTimeString;
@property (nonatomic, copy) NSString *_Nullable absTimeString;
@property (nonatomic, copy) NSString *_Nullable durationString;

- (void)setArray:(NSArray *)array;

@end


@interface UPnPTransportInfo : NSObject

@property (nonatomic, copy) NSString *_Nullable CurrentTransportState; ///< 播放状态  PLAYING、PAUSED_PLAYBACK、LOADING、STOPPED
@property (nonatomic, copy) NSString *_Nullable CurrentTransportStatus; ///< OK
@property (nonatomic, assign) NSInteger CurrentSpeed; ///< 倍速

- (void)setArray:(NSArray *)array;
@end

@interface NSString(UPnP)

+ (NSString *)stringWithDurationTime:(float)timeValue;
- (float)durationTime;

@end

NS_ASSUME_NONNULL_END
