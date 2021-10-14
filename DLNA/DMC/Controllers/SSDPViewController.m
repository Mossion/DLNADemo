//
//  SSDPViewController.m
//  workTools
//
//  Created by LTMAC on 2021/9/22.
//

#import "SSDPViewController.h"
#import "LTUPnPManager.h"
#import "GCDWebServer.h"
#import "GCDWebServerDataRequest.h"
#import "GCDWebServerDataResponse.h"
#import "GDataXMLNode.h"

@interface SSDPViewController ()<UITableViewDelegate,UITableViewDataSource,GCDWebServerDelegate,LTUPnPManagerPlayerDelegate,LTUPnPManagerBrowserDelegate>

@property (nonatomic, strong) LTUPnPManager *_Nullable upnpManager;
@property (nonatomic, strong) UPnPAVPositionInfo *_Nullable positionInfo;

@property (nonatomic, strong) UITableView *_Nullable deviceTableView;
@property (nonatomic, strong) NSArray *_Nullable deviceArray;
@property (nonatomic, strong) UIButton *_Nullable pauseButton;
@property (nonatomic, strong) UIButton *_Nullable stopButton;
@property (nonatomic, strong) UILabel *_Nullable currentTime;
@property (nonatomic, strong) UILabel *_Nullable durationTime;
@property (nonatomic, strong) UISlider *_Nullable progressSlider;
@property (nonatomic, assign) BOOL touchSlider;

@property (nonatomic, strong) GCDWebServer *_Nullable webServer;

@end

@implementation SSDPViewController

- (void)dealloc {
    NSLog(@"delloc");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"SSDP";
    self.view.backgroundColor = [UIColor whiteColor];
    [self configViews];
    [self search];
    [self startWebServer];
}

- (void)configViews {
    [self.view addSubview:self.deviceTableView];
    [self.view addSubview:self.pauseButton];
    self.pauseButton.frame = CGRectMake(0, CGRectGetMaxY(self.deviceTableView.frame) + 10, 100, 50);
    [self.view addSubview:self.stopButton];
    self.stopButton.frame = CGRectMake(CGRectGetMaxX(self.pauseButton.frame) + 10, CGRectGetMinY(self.pauseButton.frame), 100, 50);
    [self.view addSubview:self.currentTime];
    [self.view addSubview:self.durationTime];
    [self.view addSubview:self.progressSlider];
    self.currentTime.frame = CGRectMake(10, CGRectGetMaxY(self.stopButton.frame), 80, 40);
    self.durationTime.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 90, CGRectGetMaxY(self.stopButton.frame), 80, 40);
    self.progressSlider.frame = CGRectMake(CGRectGetMaxX(self.currentTime.frame)+10, CGRectGetMidY(self.currentTime.frame), [UIScreen mainScreen].bounds.size.width - 200, 5);
}

- (void)search {
//    [self.upnpBrowser startSearch];
    [self.upnpManager bowserStartSearch];
}

#pragma mark - LTUPnPManagerBrowserDelegate
- (void)upnpManager:(LTUPnPManager *)manager browserDidFindUPnPDevices:(NSArray<UPnPDevice *> *)devices {
    NSLog(@"devices:%@",devices);
    self.deviceArray = devices;
    [self.deviceTableView reloadData];
}

- (void)upnpManager:(LTUPnPManager *)manager deviceSearchError:(NSError *)error {
    NSLog(@"deviceSearch error:%@",error);
}

#pragma mark - LTUPnPManagerPlayerDelegate
- (void)upnpManager:(LTUPnPManager *)manager undefinedResponse:(NSString *)responseXml postXML:(NSString *)postXML {
    NSLog(@"%s postXML:%@",__func__,postXML);
}

- (void)upnpManager:(LTUPnPManager *)manager errorDomain:(NSError *)error {
    NSLog(@"%s error:%@",__func__, error);
}

- (void)upnpManagerAVTransportURIResponse:(LTUPnPManager *)manager {
    NSLog(@"%s",__func__);
//    NSString *callback = [NSString stringWithFormat:@"%@dlna/callback",self.webServer.serverURL.absoluteString];
    NSString *serverURLString = self.webServer.serverURL.absoluteString;
    if ([serverURLString hasSuffix:@"/"]) {
        serverURLString = [serverURLString substringToIndex:serverURLString.length-1];
    }
    [self.upnpManager managerSubscribe];
//    NSString *callback = [NSString stringWithFormat:@"%@%@",serverURLString,SERVER_CALLBACK];
//    [self.upnpConnection sendSubscribeWithTime:1800 callback:callback];
//    [self startWebServer];
}

- (void)upnpManagerPlayResponse:(LTUPnPManager *)manager {
    NSLog(@"%s",__func__);
}

- (void)upnpManagerPauseResponse:(UPnPPlayer *)player {
    NSLog(@"%s",__func__);
}

- (void)upnpManagerStopResponse:(UPnPPlayer *)player {
    NSLog(@"%s",__func__);
}

- (void)upnpManagerSeekResponse:(UPnPPlayer *)player {
    NSLog(@"%s",__func__);
}

- (void)upnpManager:(LTUPnPManager *)manager positionResponse:(UPnPAVPositionInfo *)position {
    NSLog(@"position:%@",position);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.positionInfo = position;
        self.currentTime.text = position.relTimeString;
        self.durationTime.text = position.durationString;
        self.progressSlider.value = position.progress;
    });
}

- (void)upnpManager:(LTUPnPManager *)manager transportResponse:(UPnPTransportInfo *)transport {
    NSLog(@"transport:%@",transport);
}

#pragma mark - UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.deviceArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class]) forIndexPath:indexPath];
    UPnPDevice *device = self.deviceArray[indexPath.row];
    cell.textLabel.text = device.friendlyName;
    cell.backgroundColor = [UIColor lightGrayColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UPnPDevice *device = self.deviceArray[indexPath.row];
    [self.upnpManager managerPlayUrlToUPnPDevice:device url:/*@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"*/@"http://video.hpplay.cn/demo/aom.mp4"];
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

#pragma mark - pravite method
- (void)parseWebServerMessage:(NSData *)data {
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    dataString = [self retransfer:dataString];
    NSLog(@"dataString:%@",dataString);
}

////有些设备返回的xml中 < > " 被转义，导致解析时候出错。所以需要先反转义，然后再解析。
- (NSString*)retransfer:(NSString*)string
{
    if(string == nil)return nil;
    NSString*result = [string stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    result = [result stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    result = [result stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
    return result;
}

#pragma mark - action
- (void)pauseButtonClick:(UIButton *)btn {
    btn.selected = !btn.selected;
    if (btn.selected) {
        [self.upnpManager managerPause];
    } else {
        [self.upnpManager managerPlay];
    }
}

- (void)stopButtonClick:(UIButton *)btn {
    [self.upnpManager managerStop];
}

- (void)sliderValurChanged:(UISlider *)slider forEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    switch (touch.phase) {
        case UITouchPhaseBegan:
            self.touchSlider = YES;
            break;
        case UITouchPhaseEnded:
            self.touchSlider = NO;
            [self handleSliderValueChange];
            break;
        default:
            break;
    }
}

- (void)handleSliderValueChange {
    float progress = self.progressSlider.value;
    float seekTime = progress * self.positionInfo.duration;
    NSString *seekString = [NSString stringWithDurationTime:seekTime];
    NSLog(@"seekString:%@",seekString);
    [self.upnpManager managerSeekToTime:seekString];
}

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

#pragma mark - lazy load
- (LTUPnPManager *)upnpManager {
    if (_upnpManager) {
        return _upnpManager;
    }
    _upnpManager = [[LTUPnPManager alloc] init];
    _upnpManager.browserDelegate = self;
    _upnpManager.playerDelegate = self;
    return _upnpManager;
}

- (UITableView *)deviceTableView {
    if (_deviceTableView) {
        return _deviceTableView;
    }
    _deviceTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 100, 300, 300)];
    _deviceTableView.backgroundColor = [UIColor lightGrayColor];
    _deviceTableView.tableFooterView = [UIView new];
    [_deviceTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass([UITableViewCell class])];
    _deviceTableView.delegate = self;
    _deviceTableView.dataSource = self;
    CGPoint center = _deviceTableView.center;
    center.x = self.view.center.x;
    _deviceTableView.center = center;
    return _deviceTableView;
}

- (UIButton *)pauseButton {
    if (_pauseButton) {
        return _pauseButton;
    }
    _pauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_pauseButton setTitle:@"暂停视频" forState:UIControlStateNormal];
    [_pauseButton setTitle:@"恢复播放" forState:UIControlStateSelected];
    _pauseButton.backgroundColor = [UIColor orangeColor];
    _pauseButton.layer.cornerRadius = 8;
    _pauseButton.layer.masksToBounds = YES;
    [_pauseButton addTarget:self action:@selector(pauseButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    return _pauseButton;
}

- (UIButton *)stopButton {
    if (_stopButton) {
        return _stopButton;
    }
    _stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_stopButton setTitle:@"结束播放" forState:UIControlStateNormal];
    _stopButton.backgroundColor = [UIColor orangeColor];
    _stopButton.layer.cornerRadius = 8;
    _stopButton.layer.masksToBounds = YES;
    [_stopButton addTarget:self action:@selector(stopButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    return _stopButton;
}

- (UILabel *)currentTime {
    if (_currentTime) {
        return _currentTime;
    }
    _currentTime = [[UILabel alloc] init];
    _currentTime.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    return _currentTime;
}

- (UILabel *)durationTime {
    if (_durationTime) {
        return _durationTime;
    }
    _durationTime = [[UILabel alloc] init];
    _durationTime.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    return _durationTime;
}

- (UISlider *)progressSlider {
    if (_progressSlider) {
        return _progressSlider;
    }
    _progressSlider = [[UISlider alloc] init];
    _progressSlider.value = 0.0;
    [_progressSlider addTarget:self action:@selector(sliderValurChanged:forEvent:) forControlEvents:UIControlEventValueChanged];
    return _progressSlider;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
