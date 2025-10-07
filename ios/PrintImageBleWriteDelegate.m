//
//  PrintImageBleWriteDelegate.m
//  RNBluetoothEscposPrinter
//
//  Created by januslo on 2018/10/8.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PrintImageBleWriteDelegate.h"

@implementation PrintImageBleWriteDelegate

- (void)didWriteDataToBle:(BOOL)success {
    NSLog(@"PrintImageBleWriteDelete didWriteDataToBle: %d", success ? 1 : 0);

    if (success) {
        if (_now == -1) {
            // Finish
            if (_pendingResolve) {
                _pendingResolve(nil);
                _pendingResolve = nil;
            }
        } else if (_now >= [_toPrint length]) {
            // End cmd ASCII ESC M 0 CR LF
            unsigned char initPrinter[5] = {27, 77, 0, 13, 10};
            [RNBluetoothManager writeValue:[NSData dataWithBytes:initPrinter length:5] withDelegate:self];
            _now = -1;
            [NSThread sleepForTimeInterval:0.01f];
        } else {
            [self print];
        }
    } else if (_pendingReject) {
        _pendingReject(@"PRINT_IMAGE_FAILED", @"PRINT_IMAGE_FAILED", nil);
        _pendingReject = nil;
    }
}

- (void)print {
    @synchronized (self) {
        NSInteger remaining = [_toPrint length] - _now;
        if (remaining <= 0) return;
        NSInteger bytesPerLine = (NSInteger)(_width / 8);
        NSInteger chunkSize = bytesPerLine;
        if (_linesPerChunk == 0) {
            NSInteger maxChunk = 182;
            _linesPerChunk = MAX(1, maxChunk / bytesPerLine);
        }
        chunkSize = MIN(remaining, _linesPerChunk * bytesPerLine);
        NSData *subData = [_toPrint subdataWithRange:NSMakeRange(_now, chunkSize)];
        NSLog(@"Write data (%ld bytes, %ld lines)", (long)chunkSize, (long)_linesPerChunk);
        [RNBluetoothManager writeValue:subData withDelegate:self];
        _now += chunkSize;
        [NSThread sleepForTimeInterval:0.01f];
    }
}
@end
