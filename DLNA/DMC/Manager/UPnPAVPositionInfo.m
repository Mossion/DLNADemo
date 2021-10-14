//
//  UPnPAVPositionInfo.m
//  workTools
//
//  Created by LTMAC on 2021/9/28.
//

#import "UPnPAVPositionInfo.h"
#import "GDataXMLNode.h"

@implementation UPnPAVPositionInfo

- (void)setArray:(NSArray *)array {
    for (int i = 0; i < array.count; i++) {
        GDataXMLElement *ele = array[i];
        if ([ele.name isEqualToString:@"RelTime"]) {
            self.relTimeString = ele.stringValue;
            self.relTime = [ele.stringValue durationTime];
        } else if ([ele.name isEqualToString:@"AbsTime"]) {
            self.absTimeString = ele.stringValue;
            self.absTime = [ele.stringValue durationTime];
        } else if ([ele.name isEqualToString:@"TrackDuration"]) {
            self.durationString = ele.stringValue;
            self.duration = [ele.stringValue durationTime];
        }
    }
    self.progress = self.relTime / self.duration;
}

@end

@implementation UPnPTransportInfo

- (void)setArray:(NSArray *)array {
    for (int m = 0; m < array.count; m++) {
        GDataXMLElement *element = array[m];
        if ([element.name isEqualToString:@"CurrentTransportState"]) {
            self.CurrentTransportState = element.stringValue;
        } else if ([element.name isEqualToString:@"CurrentTransportStatus"]) {
            self.CurrentTransportStatus = element.stringValue;
        } else if ([element.name isEqualToString:@"CurrentSpeed"]) {
            self.CurrentSpeed = [element.stringValue integerValue];
        }
    }
}

@end


@implementation  NSString(UPnP)
/*
 H+:MM:SS[.F+] or H+:MM:SS[.F0/F1]
 where :
 •    H+ means one or more digits to indicate elapsed hours
 •    MM means exactly 2 digits to indicate minutes (00 to 59)
 •    SS means exactly 2 digits to indicate seconds (00 to 59)
 •    [.F+] means optionally a dot followed by one or more digits to indicate fractions of seconds
 •    [.F0/F1] means optionally a dot followed by a fraction, with F0 and F1 at least one digit long, and F0 < F1
 */
+ (NSString *)stringWithDurationTime:(float)timeValue {
    return [NSString stringWithFormat:@"%02d:%02d:%02d",
            (int)(timeValue / 3600.0),
            (int)(fmod(timeValue, 3600.0) / 60.0),
            (int)fmod(timeValue, 60.0)];
}

- (float)durationTime {
    NSArray *timeStrings = [self componentsSeparatedByString:@":"];
    int timeStringsCount = (int)[timeStrings count];
    if (timeStringsCount < 3)
        return -1.0f;
    float durationTime = 0.0;
    for (int n = 0; n<timeStringsCount; n++) {
        NSString *timeString = [timeStrings objectAtIndex:n];
        int timeIntValue = [timeString intValue];
        switch (n) {
            case 0: // HH
                durationTime += timeIntValue * (60 * 60);
                break;
            case 1: // MM
                durationTime += timeIntValue * 60;
                break;
            case 2: // SS
                durationTime += timeIntValue;
                break;
            case 3: // .F?
                durationTime += timeIntValue * 0.1;
                break;
            default:
                break;
        }
    }
    return durationTime;
}

@end
