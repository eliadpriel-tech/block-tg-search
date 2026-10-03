#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface UIWindow (BlockSearch)
@end

@implementation UIWindow (BlockSearch)

- (UIView *)swizzled_hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIViewController *root = self.rootViewController;
    
    // אם לא מוצג חלון מודאלי חיצוני (כמו מסך העברה/שיתוף)
    if (root.presentedViewController == nil) {
        // טווח הגובה של שורת החיפוש העליונה באייפון 11
        if (point.y >= 44 && point.y <= 135) {
            return nil; // מבטל לחלוטין את המגע באזור הזה
        }
    }
    
    return [self swizzled_hitTest:point withEvent:event];
}

@end

__attribute__((constructor)) static void init(void) {
    Class class = [UIWindow class];
    SEL originalSelector = @selector(hitTest:withEvent:);
    SEL swizzledSelector = @selector(swizzled_hitTest:withEvent:);

    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    method_exchangeImplementations(originalMethod, swizzledMethod);
}
