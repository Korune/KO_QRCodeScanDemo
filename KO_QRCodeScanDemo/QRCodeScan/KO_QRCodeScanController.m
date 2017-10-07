//
//  KO_QRCodeScanController.m
//  KO_QRCodeScanDemo
//
//  Created by Korune on 2017/9/3.
//  Copyright © 2017年 Korune. All rights reserved.
//

#import "KO_QRCodeScanController.h"
#import <AVFoundation/AVFoundation.h>
#import "KOFinderView.h"

#define KO_SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define KO_SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface KO_QRCodeScanController ()<AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong)AVCaptureSession *captureSession;
@property (nonatomic, strong)AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong)AVCaptureDevice *captureDevice;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UIImageView *scanLineImageView;

@property (nonatomic, strong) NSTimer *scanLineTimer;
/** 取景显示的区域（即中间的正方形区域）frame */
@property (nonatomic) CGRect finderViewRect;
/** 二维码实际的扫描区域(可以为整个屏幕区域) */
@property (nonatomic) CGRect rectOfInterest;

@property (nonatomic) CGRect scanLineImageViewOriginalFrame;

@end

@implementation KO_QRCodeScanController

- (instancetype)init
{
    if (self = [super init]) {
        self.QRScanDisplayStyle = KO_QRScanDisplayStyleOne;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupPreviewLayer];
    [self setupSubViews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //
    self.navigationController.navigationBar.hidden = YES;
    UIApplication *application = [UIApplication sharedApplication];
    [application setStatusBarHidden:YES];
    
    // 判断是否能进行二维码扫描
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error) {
        NSLog(@"没有摄像头%@", error.localizedDescription);
        input = nil;
        
        NSString *message = [NSString stringWithFormat:@"Error:%@.", error.localizedDescription];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"无法使用二维码扫描"
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"确定"
                                                  otherButtonTitles: nil];
        [alertView show];
        return;
    }
    
    // 6.启动会话
    [self.captureSession startRunning];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    NSLog(@"导航条高度：%@", NSStringFromCGRect([UIApplication sharedApplication].statusBarFrame));
    
    // 设置定时器，最好放在 - viewDidAppear: 方法 中，放在 - viewDidLoad 、- viewWillAppear: 方法中，可能导致扫描线的第二次动画错误显示。
    if (self.scanLineTimer == nil) {
        [self createTimer];
        self.scanLineTimer.fireDate = [NSDate distantPast];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBar.hidden = NO;
    UIApplication *application = [UIApplication sharedApplication];
    [application setStatusBarHidden:NO];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // 删除预览图层
    [self.previewLayer removeFromSuperlayer];
    
    [self.scanLineTimer invalidate];
    self.scanLineTimer = nil;
}

- (void)dealloc
{
    NSLog(@"%s", __FUNCTION__);
}

#pragma mark - 初始化

- (CGRect)rectOfInterest
{
    /*
      rectOfInterest = CGRectMake(y / previewLayerHeight, x / previewLayerWidth, height / previewLayerHeight, width / previewLayerWidth);
      解释下:都把x、y、width、height 互换了的。你扫一扫的那个框框的起点坐标为x、y，宽为width，高为height。previewLayerWidth ,previewLayerHeight指的是AVCaptureVideoPreviewLayer对象的宽高。
     */
    if (CGRectEqualToRect(_rectOfInterest, CGRectZero) ) {
        if (_QRScanDisplayStyle == KO_QRScanDisplayStyleOne) {
            _rectOfInterest = CGRectMake(self.finderViewRect.origin.y / KO_SCREEN_HEIGHT,
                                         self.finderViewRect.origin.x / KO_SCREEN_WIDTH,
                                         self.finderViewRect.size.height / KO_SCREEN_HEIGHT,
                                         self.finderViewRect.size.width / KO_SCREEN_WIDTH
                                         );
        } else if (_QRScanDisplayStyle == KO_QRScanDisplayStyleTwo) {
            _rectOfInterest = CGRectMake(0, 0, 1, 1);
        }
    }
    return _rectOfInterest;
}

- (CGRect)finderViewRect
{
    if (CGRectEqualToRect(_finderViewRect, CGRectZero)) {
        CGFloat viewFinderW = KO_SCREEN_WIDTH * 0.6;
        CGFloat viewFinderH = viewFinderW;
        CGFloat viewFinderX = (KO_SCREEN_WIDTH - viewFinderW)/2;
        CGFloat viewFinderY = (KO_SCREEN_HEIGHT - viewFinderW)/2;
        _finderViewRect = CGRectMake(viewFinderX, viewFinderY, viewFinderW, viewFinderH);
    }
    return _finderViewRect;
}

- (void)setupPreviewLayer
{
    // 1 实例化摄像头设备
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.captureDevice = captureDevice;
    
    // 2 设置输入,把摄像头作为输入设备
    // 因为模拟器是没有摄像头的，因此在此最好做个判断
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];
    if (error) {
        NSLog(@"没有摄像头，或者其他错误，Error：%@", error.localizedDescription);
        return;
    }
    
    // 3 设置输出(Metadata元数据)
    AVCaptureMetadataOutput *outPut = [[AVCaptureMetadataOutput alloc] init];
    
    // 设置扫描范围(每一个取值0～1，以屏幕右上角为坐标原点)
    // 注：微信二维码的扫描范围是整个屏幕， 这里进行了处理（可不用设置）
    outPut.rectOfInterest = self.rectOfInterest;
    NSLog(@"设置的 rectOfInterest 区域为：%@",NSStringFromCGRect(self.rectOfInterest));
    
    // 3.1 设置输出的代理
    // 使用主线程队列，相应比较同步，使用其他队列，相应不同步，容易让用户产生不好的体验。
    [outPut setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // 4 拍摄会话
    AVCaptureSession *session = [[AVCaptureSession alloc]init];
    session.sessionPreset = AVCaptureSessionPreset640x480;
    // 添加session的输入和输出
    [session addInput:input];
    [session addOutput:outPut];
    self.captureSession = session;
    
    // 4.1 设置输出的格式
    [outPut setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    
    // 5 设置预览图层(用来让用户能够看到扫描情况)
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    
    // 5.1 设置preview图层的属性
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    // 5.2设置preview图层的大小
    if (self.QRScanDisplayStyle == KO_QRScanDisplayStyleOne) {
        previewLayer.frame = self.view.bounds;
    } else if (self.QRScanDisplayStyle == KO_QRScanDisplayStyleTwo) {
        previewLayer.frame = self.finderViewRect;
    }
    NSLog(@"previewLayer 设置的 frame 为：%@", NSStringFromCGRect(previewLayer.frame));
    
    self.previewLayer = previewLayer;
    
    // 5.3将图层添加到视图的图层
    [self.view.layer insertSublayer:previewLayer atIndex:0];
}

- (void)setupSubViews
{
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 取景器视图
    KOFinderView *finderView = [KOFinderView finderViewWithFrame:self.finderViewRect];
    [self.view addSubview:finderView];
    
    // 移动的线
    CGRect lineOriginalFrame = CGRectMake(self.finderViewRect.origin.x, self.finderViewRect.origin.y, self.finderViewRect.size.width, 10);
    self.scanLineImageViewOriginalFrame = lineOriginalFrame;
    self.scanLineImageView = [[UIImageView alloc] initWithFrame:self.scanLineImageViewOriginalFrame];
    self.scanLineImageView.image = [UIImage imageNamed:@"qr_scan_line"];
    [self.view addSubview:self.scanLineImageView];
    
    // 配置取景框之外视图
    if (self.QRScanDisplayStyle == KO_QRScanDisplayStyleOne) {
        [self setupBorderView];
    }
    
    // 返回键
    UIButton *goBackButton = ({
        UIButton *button =
        [[UIButton alloc] initWithFrame:CGRectMake(20, 30, 36, 36)];
        [button setImage:[UIImage imageNamed:@"qr_vc_left"] forState:UIControlStateNormal];
        button.layer.cornerRadius = 18.0;
        button.layer.backgroundColor = [[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5] CGColor];
        [button addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchDown];
        button;
    });
    [self.view addSubview:goBackButton];
    
    // 控制散光灯
    UIButton *torchSwitch = ({
        UIButton *button =
        [[UIButton alloc] initWithFrame:CGRectMake(KO_SCREEN_WIDTH - 36 - 20, 30, 36, 36)];
        [button setImage:[UIImage imageNamed:@"qr_vc_right"] forState:UIControlStateNormal];
        button.layer.cornerRadius = 18.0;
        button.layer.backgroundColor = [[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5] CGColor];
        [button addTarget:self action:@selector(torchSwitch:) forControlEvents:UIControlEventTouchDown];
        button;
    });
    
    if (!self.captureDevice.hasTorch) {  // 判断设备是否有散光灯
        torchSwitch.hidden = YES;
    }
    
    [self.view addSubview:torchSwitch];
    
    // 信息提示Label
    UILabel *infoLabel = ({
        NSString *info = @"将二维码放入取景框中，即可自动扫描";
        CGSize maxSize = CGSizeMake(KO_SCREEN_WIDTH - 20 * 2, MAXFLOAT);
        NSDictionary *attributes = @{ NSFontAttributeName : [UIFont systemFontOfSize:14.0] };
        CGRect rect = [info boundingRectWithSize:maxSize
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:attributes
                                         context:nil];
        
        CGFloat labelX = (KO_SCREEN_WIDTH - rect.size.width) / 2.0;
        CGFloat labelY = CGRectGetMaxY(self.finderViewRect) + (KO_SCREEN_HEIGHT - CGRectGetMaxY(self.finderViewRect)) * 0.3;
        UILabel *label =  [[UILabel alloc] initWithFrame:CGRectMake(labelX, labelY, rect.size.width + 20, rect.size.height + 20)];
        
        label.text = info;
        label.font = [UIFont systemFontOfSize:14.0];
        label.layer.cornerRadius = label.frame.size.height / 2;
        label.layer.backgroundColor = [[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5] CGColor];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label;
    });
    self.infoLabel = infoLabel;
    
    [self.view addSubview:infoLabel];
}

/** 设置四周边界视图 */
- (void)setupBorderView
{
    // 配置取景框之外视图颜色
    UIView *topView =
    [[UIView alloc] initWithFrame:CGRectMake(0, 0, KO_SCREEN_WIDTH, self.finderViewRect.origin.y)];
    
    UIView *bottomView =
    [[UIView alloc] initWithFrame:CGRectMake(0,
                                             CGRectGetMaxY(self.finderViewRect),
                                             KO_SCREEN_WIDTH,
                                             KO_SCREEN_HEIGHT - CGRectGetMaxY(self.finderViewRect))];
    
    UIView *leftView =
    [[UIView alloc] initWithFrame:CGRectMake(0,
                                             self.finderViewRect.origin.y,
                                             self.finderViewRect.origin.x,
                                             self.finderViewRect.size.height)];
    
    UIView *rightView =
    [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.finderViewRect),
                                             self.finderViewRect.origin.y,
                                             KO_SCREEN_WIDTH - CGRectGetMaxX(self.finderViewRect),
                                             self.finderViewRect.size.height)];
    
    topView.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.2];
    bottomView.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.2];
    leftView.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.2];
    rightView.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.2];
    
    [self.view addSubview:topView];
    [self.view addSubview:bottomView];
    [self.view addSubview:leftView];
    [self.view addSubview:rightView];
}

#pragma mark - 其他

// 返回
- (void)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

// 控制散光灯
- (void)torchSwitch:(id)sender {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    if (device.hasTorch) {  // 判断设备是否有散光灯
        BOOL b = [device lockForConfiguration:&error];
        if (!b) {
            if (error) {
                NSLog(@"lock torch configuration error:%@", error.localizedDescription);
            }
            return;
        }
        device.torchMode =
        (device.torchMode == AVCaptureTorchModeOff ? AVCaptureTorchModeOn : AVCaptureTorchModeOff);
        [device unlockForConfiguration];
    }
}

#define LINE_SCAN_TIME  3.0     // 扫描线从上到下扫描所历时间（s）

- (void)createTimer {
    self.scanLineTimer = [NSTimer timerWithTimeInterval:LINE_SCAN_TIME
                                                          target:self
                                                        selector:@selector(moveUpAndDownLine)
                                                        userInfo:nil
                                                         repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.scanLineTimer forMode:NSRunLoopCommonModes];
}

// 扫描条上下滚动
- (void)moveUpAndDownLine {
    
    self.scanLineImageView.hidden = NO;  // 设置 hidden 为 YES、NO 是为了在程序进入前台后，一会后进入前台“线”的位置在最底下情况。
    self.scanLineImageView.frame = self.scanLineImageViewOriginalFrame; // 这句代码最好不好放在动画完成的 block 里，实测发现如果放在此 block，在以一次 NSTimer 动画完成后，线会错位。
    NSLog(@"定时器开始");
    [UIView animateWithDuration:LINE_SCAN_TIME - 0.05 // 动画时间最好不要设置为 LINE_SCAN_TIME，要设置时间少一些。避免动画完后和下一次定时器同时执行出现异常情况
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         
                         NSLog(@"动画开始");
                         CGRect frame = self.scanLineImageView.frame;
                         frame.origin.y = CGRectGetMaxY(self.finderViewRect) - frame.size.height;
                         self.scanLineImageView.frame = frame;
                         NSLog(@"Rect:%@", NSStringFromCGRect(self.scanLineImageViewOriginalFrame));
                     } completion:^(BOOL finished) {
                         
                         NSLog(@"动画完成");
                         self.scanLineImageView.hidden = YES;
                         NSLog(@"___________________________");
                     }];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate 相关

//此方法是在识别到QRCode并且完成转换，如果QRCode的内容越大，转换需要的时间就越长。
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    // 会频繁的扫描，调用代理方法
    // 1如果扫描完成，停止会话
    [self.captureSession stopRunning];
    [self playSoundEffect:@"ding.wav"];
    
    // 设置界面显示扫描结果
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *obj = metadataObjects[0];
        NSLog(@"扫描结果为：%@", obj.stringValue);
        if ([self.delegate respondsToSelector:@selector(KO_QRCodeScanController: didFinishedReadingQR:)]) {
            [self.delegate KO_QRCodeScanController:self didFinishedReadingQR:obj.stringValue];
        }
    }
    [self performSelector:@selector(popViewController) withObject:nil afterDelay:0.2];
}

- (void)popViewController
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)playSoundEffect:(NSString *)name
{
    NSString *audioFile = [[NSBundle mainBundle] pathForResource:name ofType:nil];
    NSURL *fileUrl = [NSURL fileURLWithPath:audioFile];

    SystemSoundID soundID = 0;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(fileUrl), &soundID);
    AudioServicesPlaySystemSound(soundID);//播放音效
}

@end
