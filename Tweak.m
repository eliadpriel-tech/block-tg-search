#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// נטרול הפוקוס של מקלדת החיפוש - מונע את פתיחת החיפוש הגלובלי
@implementation UITextField (BlockGlobalSearch)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(becomeFirstResponder);
        SEL swizzledSelector = @selector(custom_becomeFirstResponder);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        if (originalMethod && swizzledMethod) {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (BOOL)custom_becomeFirstResponder {
    // בדיקה האם מדובר בשדה חיפוש של המסך הראשי
    NSString *className = NSStringFromClass([self class]);
    UIView *superV = self.superview;
    NSString *superClassName = superV ? NSStringFromClass([superV class]) : @"";
    
    // אם הרכיב קשור ל-Search של המסך הראשי (UISearchBar / SearchField)
    if ([className containsString:@"Search"] || [superClassName containsString:@"Search"]) {
        // בודק אם אנחנו במסך ראשי ולא בחלון שיתוף/העברה
        UIResponder *responder = self;
        while (responder.nextResponder) {
            responder = responder.nextResponder;
            if ([responder isKindOfClass:[UIViewController class]]) {
                UIViewController *vc = (UIViewController *)responder;
                // אם זה מסך מודאלי (Forward/Share), נאפשר חיפוש
                if (vc.presentingViewController != nil) {
                    return [self custom_becomeFirstResponder];
                }
                break;
            }
        }
        // חסימת פתיחת המקלדת עבור חיפוש ראשי
        return NO;
    }
    
    return [self custom_becomeFirstResponder];
}

@end
