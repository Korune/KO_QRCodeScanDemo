# KO_QRCodeScanDemo

## 简介

使用 iOS 原生 API 实现的简单二维码扫描功能。
扫描界面有两种样式：
* 1、二维码扫描预览界面为整个界面。
* 2、二维码扫描预览界面为扫描的区域。

## 效果图

![](https://github.com/Korune/KO_QRCodeScanDemo/blob/master/Screenshots/IMG_2.PNG)

![](https://github.com/Korune/KO_QRCodeScanDemo/blob/master/Screenshots/IMG_3.PNG)

## 涉及涉及知识点：
* 二维码扫描
* 扫描线动画
* 扫描成功后播放提示音

## 代码介绍

#### 1、扫描二维码后处理的代理方法
```Objective-C
- (void)KO_QRCodeScanController:(KO_QRCodeScanController *)QRCodeScanController
didFinishedReadingQR:(NSString *)string;
```

#### 2、代码关键点
* 使用 KOFinderView 来显示正方形的取景器区域
* `- moveUpAndDownLine` 方法中扫描线的动画
* `AVCaptureMetadataOutput`  对象的 `rectOfInterest`（扫描区域） 属性设置


