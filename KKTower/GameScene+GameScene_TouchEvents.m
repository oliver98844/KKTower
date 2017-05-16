//
//  GameScene+GameScene_TouchEvents.m
//  KKTower
//
//  Created by Oliver Huang on 2017/5/16.
//  Copyright © 2017年 KKBOX. All rights reserved.
//

#import "GameScene+GameScene_TouchEvents.h"

@implementation GameScene (TouchEvents)

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[self swiftTouchesBegan:touches with:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[self swiftTouchesMoved:touches with:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[self swiftTouchesEnded:touches with:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[self swiftTouchesCancelled:touches with:event];
}

@end
