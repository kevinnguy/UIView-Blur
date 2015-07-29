//
//  UIView+Blur.m
//  testBlurredUIView
//
//  Created by salah on 2014-05-21.
//  Copyright (c) 2014 Mike All rights reserved.
//

#import "UIView+Blur.h"

#import <objc/runtime.h>

NSString const *kBlurBackgroundKey = @"blurBackgroundKey";
NSString const *kBlurVibrancyBackgroundKey = @"blurVibrancyBackgroundKey";
NSString const *kBlurTintColorKey = @"blurTintColorKey";
NSString const *kBlurTintColorIntensityKey = @"blurTintColorIntensityKey";
NSString const *kBlurTintColorLayerKey = @"blurTintColorLayerKey";
NSString const *kBlurStyleKey = @"blurStyleKey";

@implementation UIView (Blur)

@dynamic blurBackground;
@dynamic blurTintColor;
@dynamic blurTintColorIntensity;
@dynamic isBlurred;
@dynamic blurStyle;

#pragma mark - category methods
- (void)enableBlur:(BOOL)enable {
    if (enable) {
        if (IOS_MAJOR_VERSION >= 8) {
            UIVisualEffectView *view = (UIVisualEffectView *)self.blurBackground;
            UIVisualEffectView *vibrancyView = self.blurVibrancyBackground;
            if (!view || !vibrancyView) {
                [self blurBuildBlurAndVibrancyViews];
            }
        } else {
            UIToolbar *view = (UIToolbar *)self.blurBackground;
            if (!view) {
                // use UIToolbar
                view = [[UIToolbar alloc] initWithFrame:self.bounds];
                objc_setAssociatedObject(self, &kBlurBackgroundKey, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            
            [view setFrame:self.bounds];
            view.clipsToBounds = YES;
            view.translucent = YES;
            
            // add the toolbar layer as sublayer
            [self.layer insertSublayer:view.layer atIndex:0];
        }
    } else {
        if (!self.blurBackground) {
            return;
        }
        
        if (IOS_MAJOR_VERSION >= 8) {
            [self.blurBackground removeFromSuperview];
            objc_setAssociatedObject(self, &kBlurBackgroundKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        } else {
            [self.blurBackground.layer removeFromSuperlayer];
        }
    }
}

- (void)blurBuildBlurAndVibrancyViews NS_AVAILABLE_IOS(8_0) {
    UIBlurEffectStyle style;
    switch (self.blurStyle) {
        case UIViewBlurDarkStyle: {
            style = UIBlurEffectStyleDark;
            break;
        }
            
        case UIViewBlurExtraLightStyle: {
            style = UIBlurEffectStyleExtraLight;
            break;
        }
            
        case UIViewBlurLightStyle: {
            style = UIBlurEffectStyleLight;
            break;
        }
            
        default:
            break;
    }
    
    // use UIVisualEffectView
    UIVisualEffectView *view = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:style]];
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    view.frame = self.bounds;
    [self addSubview:view];
    objc_setAssociatedObject(self, &kBlurBackgroundKey, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // save subviews of existing vibrancy view
    NSArray *subviews = self.blurVibrancyBackground.contentView.subviews;
    
    // create vibrancy view
    UIVisualEffectView *vibrancyView = [[UIVisualEffectView alloc] initWithEffect:[UIVibrancyEffect effectForBlurEffect:(UIBlurEffect *)view.effect]];
    vibrancyView.frame = self.bounds;
    [view.contentView addSubview:vibrancyView];
    view.contentView.backgroundColor = [self.blurTintColor colorWithAlphaComponent:self.blurTintColorIntensity];
    
    // add back subviews to vibrancy view
    if (subviews.count) {
        for (UIView *view in subviews) {
            [vibrancyView.contentView addSubview:view];
        }
    }
    objc_setAssociatedObject(self, &kBlurVibrancyBackgroundKey, vibrancyView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - getters/setters
- (UIColor *)blurTintColor {
    UIColor *color = objc_getAssociatedObject(self, &kBlurTintColorKey);
    if (!color) {
        color = [UIColor clearColor];
        objc_setAssociatedObject(self, &kBlurTintColorKey, color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return color;
}

- (void)setBlurTintColor:(UIColor *)blurTintColor {
    objc_setAssociatedObject(self, &kBlurTintColorKey, blurTintColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (IOS_MAJOR_VERSION >= 8) {
        ((UIVisualEffectView *)self.blurBackground).contentView.backgroundColor = [blurTintColor colorWithAlphaComponent:self.blurTintColorIntensity];
    } else {
        if (!self.blurBackground) {
            return;
        }

        UIToolbar *toolbar = ((UIToolbar *)self.blurBackground);
        CALayer *colorLayer = objc_getAssociatedObject(self, &kBlurTintColorLayerKey);
        if (colorLayer) {
            [colorLayer removeFromSuperlayer];
        } else {
            colorLayer = [CALayer layer];
        }
        
        toolbar.barStyle = self.blurStyle == UIViewBlurDarkStyle ? UIBarStyleBlackTranslucent : UIBarStyleDefault;

        colorLayer.frame = toolbar.frame;
        colorLayer.opacity = 0.5f * self.blurTintColorIntensity;
        colorLayer.opaque = NO;
        [toolbar.layer insertSublayer:colorLayer atIndex:1];
        colorLayer.backgroundColor = blurTintColor.CGColor;
        
        objc_setAssociatedObject(self, &kBlurTintColorLayerKey, colorLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (UIView *)blurBackground {
    return objc_getAssociatedObject(self, &kBlurBackgroundKey);
}

- (UIVisualEffectView *)blurVibrancyBackground NS_AVAILABLE_IOS(8_0) {
    return objc_getAssociatedObject(self, &kBlurVibrancyBackgroundKey);
}

- (UIViewBlurStyle)blurStyle {
    NSNumber *style = objc_getAssociatedObject(self, &kBlurStyleKey);
    if(!style) {
        style = @0;
    }
    return (UIViewBlurStyle)style.integerValue;
}

- (void)setBlurStyle:(UIViewBlurStyle)viewBlurStyle {
    NSNumber *style = [NSNumber numberWithInteger:viewBlurStyle];
    objc_setAssociatedObject(self, &kBlurStyleKey, style, OBJC_ASSOCIATION_RETAIN);
    
    if (!self.blurBackground) {
        return;
    }
    
    if (IOS_MAJOR_VERSION >= 8) {
        [self.blurBackground removeFromSuperview];
        [self blurBuildBlurAndVibrancyViews];
    } else {
        ((UIToolbar *)self.blurBackground).barStyle = viewBlurStyle == UIViewBlurDarkStyle ? UIBarStyleBlackTranslucent : UIBarStyleDefault;
    }
}

- (void)setBlurTintColorIntensity:(double)blurTintColorIntensity {
    NSNumber *intensity = [NSNumber numberWithDouble:blurTintColorIntensity];
    objc_setAssociatedObject(self, &kBlurTintColorIntensityKey, intensity, OBJC_ASSOCIATION_RETAIN);
    
    if (IOS_MAJOR_VERSION >= 8 || !self.blurBackground) {
        return;
    }
    
    CALayer *colorLayer = objc_getAssociatedObject(self, &kBlurTintColorLayerKey);
    if(colorLayer) {
        colorLayer.opacity = 0.5f * intensity.floatValue;
    }
}

- (double)blurTintColorIntensity {
    NSNumber *intensity = objc_getAssociatedObject(self, &kBlurTintColorIntensityKey);
    if (!intensity) {
        intensity = @0.3;
    }
    return intensity.doubleValue;
}

@end
