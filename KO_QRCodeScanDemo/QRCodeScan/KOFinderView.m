//
//  KOFinderView.m
//  KO_QRCodeScanDemo
//
//  Created by Korune on 2017/10/6.
//  Copyright © 2017年 Korune. All rights reserved.
//

#import "KOFinderView.h"

@interface KOFinderView()

@end

@implementation KOFinderView

+ (instancetype)finderViewWithFrame:(CGRect )frame
{
    return [[self alloc] initWithFrame:frame];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setupChildView];
    }
    return self;
}

- (void)setupChildView
{
    /* 画一个取景框开始 */
    
    UIImage *topLetfImage = [UIImage imageNamed:@"qr_top_left.png"];
    CGFloat imageW = topLetfImage.size.width;
    CGFloat imageH = topLetfImage.size.height;
    
    UIImageView *topLeft = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, imageW, imageH)];
    topLeft.image = topLetfImage;
    [self addSubview:topLeft];
    
    UIImageView *topRight = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - imageW, 0, imageW, imageH)];
    topRight.image = [UIImage imageNamed:@"qr_top_right.png"];
    [self addSubview:topRight];
    
    UIImageView *bottomLeft = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - imageH, imageW, imageH)];
    bottomLeft.image = [UIImage imageNamed:@"qr_bottom_left"];
    [self addSubview:bottomLeft];
    
    UIImageView *bottomRight = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - imageW, self.frame.size.height - imageH, imageW, imageH)];
    bottomRight.image = [UIImage imageNamed:@"qr_bottom_right"];
    [self addSubview:bottomRight];
    
    // 划线
    
    CGFloat lineCu = 1; // 线的粗度
    CGFloat topLineX = 0 - lineCu;
    CGFloat topLineY = 0 - lineCu;
    CGFloat topLineW = self.frame.size.width + lineCu * 2;
    CGFloat topLineH = lineCu;
    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(topLineX, topLineY, topLineW, topLineH)];
    topLine.backgroundColor = [UIColor grayColor];
    [self addSubview:topLine];
    
    CGFloat bottomLineX = 0 - lineCu;
    CGFloat bottomLineY = self.frame.size.height;
    CGFloat bottomLineW = self.frame.size.width + lineCu * 2;
    CGFloat bottomLineH = lineCu;
    UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(bottomLineX, bottomLineY, bottomLineW, bottomLineH)];
    bottomLine.backgroundColor = [UIColor grayColor];
    [self addSubview:bottomLine];
    
    CGFloat leftLineX = 0 - lineCu;
    CGFloat leftLineY = 0 - lineCu;
    CGFloat leftLineW = lineCu;
    CGFloat leftLineH = self.frame.size.height + lineCu * 2;
    UIView *leftLine = [[UIView alloc] initWithFrame:CGRectMake(leftLineX, leftLineY, leftLineW, leftLineH)];
    leftLine.backgroundColor = [UIColor grayColor];
    [self addSubview:leftLine];
    
    CGFloat rightLineX = self.frame.size.width;
    CGFloat rightLineY = 0 - lineCu;
    CGFloat rightLineW = lineCu;
    CGFloat rightLineH = self.frame.size.height + lineCu * 2;
    UIView *rightLine = [[UIView alloc] initWithFrame:CGRectMake(rightLineX, rightLineY, rightLineW, rightLineH)];
    rightLine.backgroundColor = [UIColor grayColor];
    [self addSubview:rightLine];
    
    /* 画一个取景框结束 */
}

@end
