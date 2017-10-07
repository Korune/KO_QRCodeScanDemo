//
//  ViewController.m
//  KO_QRCodeScanDemo
//
//  Created by Korune on 2017/9/3.
//  Copyright © 2017年 Korune. All rights reserved.
//

#import "ViewController.h"
#import "KO_QRCodeScanController.h"

@interface ViewController ()<KO_QRCodeScanControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *resultLabel1;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel2;

- (IBAction)styleOneButtonOnClicked:(id)sender;
- (IBAction)styleTwoButtonOnClicked:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)styleOneButtonOnClicked:(id)sender {
    
    KO_QRCodeScanController *vc = [[KO_QRCodeScanController alloc] init];
    vc.delegate = self;
    vc.QRScanDisplayStyle = KO_QRScanDisplayStyleOne;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)styleTwoButtonOnClicked:(id)sender {
    KO_QRCodeScanController *vc = [[KO_QRCodeScanController alloc] init];
    vc.delegate = self;
    vc.QRScanDisplayStyle = KO_QRScanDisplayStyleTwo;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)KO_QRCodeScanController:(KO_QRCodeScanController *)QRCodeScanController
            didFinishedReadingQR:(NSString *)string
{
    if (QRCodeScanController.QRScanDisplayStyle == KO_QRScanDisplayStyleOne) {
        self.resultLabel1.text = [NSString stringWithFormat:@"扫描结果为：%@", string];
    } else if (QRCodeScanController.QRScanDisplayStyle == KO_QRScanDisplayStyleTwo) {
        self.resultLabel2.text = [NSString stringWithFormat:@"扫描结果为：%@", string];
    }
    
}
@end
