//
//  KO_QRCodeScanController.h
//  KO_QRCodeScanDemo
//
//  Created by Korune on 2017/9/3.
//  Copyright © 2017年 Korune. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, KO_QRScanDisplayStyle) {
    KO_QRScanDisplayStyleOne, // 界面全部显示摄像头内容
    KO_QRScanDisplayStyleTwo, // 界面取景器范围才显示摄像头内容
};

@class KO_QRCodeScanController;
@protocol KO_QRCodeScanControllerDelegate <NSObject>

@optional
- (void)KO_QRCodeScanController:(KO_QRCodeScanController *)QRCodeScanController
            didFinishedReadingQR:(NSString *)string;
@end

@interface KO_QRCodeScanController : UIViewController

@property (nonatomic, weak) id<KO_QRCodeScanControllerDelegate> delegate;
@property (nonatomic) KO_QRScanDisplayStyle QRScanDisplayStyle;

@end
