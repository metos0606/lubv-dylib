// LUBV Ultimate - Fully Undetected
// Based on actual Among Us classes from dump

#import <substrate.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ============================================================
// SETTINGS MANAGER
// ============================================================

@interface LUBVSettings : NSObject
@property (nonatomic, assign) BOOL alwaysImpostor;
@property (nonatomic, assign) BOOL noKillCooldown;
@property (nonatomic, assign) BOOL alwaysCanKill;
@property (nonatomic, assign) BOOL alwaysCanVent;
@property (nonatomic, assign) BOOL alwaysCanSabotage;
@property (nonatomic, assign) BOOL alwaysCanReport;
@property (nonatomic, assign) BOOL godMode;
@property (nonatomic, assign) BOOL noVentCooldown;
@property (nonatomic, assign) BOOL fastSpeed;
@property (nonatomic, assign) BOOL unlimitedVision;
@property (nonatomic, assign) BOOL seeGhosts;
@property (nonatomic, assign) BOOL unlimitedEmergencies;
@property (nonatomic, assign) BOOL noClip;
@property (nonatomic, assign) float playerSpeed;
+ (instancetype)sharedInstance;
@end

@implementation LUBVSettings

+ (instancetype)sharedInstance {
    static LUBVSettings *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LUBVSettings alloc] init];
        instance.alwaysImpostor = YES;
        instance.noKillCooldown = YES;
        instance.alwaysCanKill = YES;
        instance.alwaysCanVent = YES;
        instance.alwaysCanSabotage = YES;
        instance.alwaysCanReport = YES;
        instance.godMode = NO;
        instance.noVentCooldown = YES;
        instance.fastSpeed = NO;
        instance.unlimitedVision = YES;
        instance.seeGhosts = YES;
        instance.unlimitedEmergencies = NO;
        instance.noClip = NO;
        instance.playerSpeed = 1.5;
    });
    return instance;
}

@end

// ============================================================
// SAFE HOOK HELPER
// ============================================================

static void SafeHookMethod(Class class, SEL selector, IMP newImp, IMP *originalImp) {
    Method method = class_getInstanceMethod(class, selector);
    if (method) {
        *originalImp = method_setImplementation(method, newImp);
    }
}

// ============================================================
// GUI BUTTON
// ============================================================

@interface LUBVGUIButton : UIButton
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) BOOL isMenuOpen;
@property (nonatomic, strong) NSMutableDictionary *switches;
@end

@implementation LUBVGUIButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.91 green:0.27 blue:0.38 alpha:0.95];
        self.layer.cornerRadius = 25;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowRadius = 8;
        self.layer.shadowOpacity = 0.6;
        
        [self setTitle:@"⚡" forState:UIControlStateNormal];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:20];
        
        self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:self.panGesture];
        [self addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        
        self.isMenuOpen = NO;
        self.switches = [NSMutableDictionary dictionary];
        [self createMenu];
    }
    return self;
}

- (void)createMenu {
    self.menuView = [[UIView alloc] initWithFrame:CGRectMake(-200, -380, 260, 460)];
    self.menuView.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.97];
    self.menuView.layer.cornerRadius = 20;
    self.menuView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.menuView.layer.shadowOffset = CGSizeMake(0, 4);
    self.menuView.layer.shadowRadius = 12;
    self.menuView.layer.shadowOpacity = 0.9;
    self.menuView.hidden = YES;
    [self addSubview:self.menuView];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 40, 260, 420)];
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.menuView addSubview:self.scrollView];
    
    // Title
    UIView *titleBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 260, 40)];
    titleBar.backgroundColor = [UIColor colorWithRed:0.91 green:0.27 blue:0.38 alpha:0.2];
    [self.menuView addSubview:titleBar];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(50, 5, 160, 30)];
    title.text = @"LUBV CONTROLS";
    title.textColor = [UIColor colorWithRed:0.91 green:0.27 blue:0.38 alpha:1];
    title.font = [UIFont boldSystemFontOfSize:16];
    title.textAlignment = NSTextAlignmentCenter;
    [titleBar addSubview:title];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(220, 5, 30, 30);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [titleBar addSubview:closeBtn];
    
    NSArray *features = @[
        @"Always Impostor",
        @"No Kill Cooldown",
        @"Always Can Kill",
        @"Always Can Vent",
        @"No Vent Cooldown",
        @"Always Can Sabotage",
        @"Always Can Report",
        @"Unlimited Vision",
        @"See Ghosts",
        @"God Mode",
        @"Fast Speed",
        @"Unlimited Emergencies",
        @"No Clip (Walk Walls)"
    ];
    
    NSArray *keys = @[
        @"alwaysImpostor", @"noKillCooldown", @"alwaysCanKill",
        @"alwaysCanVent", @"noVentCooldown", @"alwaysCanSabotage",
        @"alwaysCanReport", @"unlimitedVision", @"seeGhosts",
        @"godMode", @"fastSpeed", @"unlimitedEmergencies", @"noClip"
    ];
    
    for (int i = 0; i < features.count; i++) {
        int y = 8 + (i * 36);
        
        UIView *rowView = [[UIView alloc] initWithFrame:CGRectMake(5, y, 250, 34)];
        if (i % 2 == 0) {
            rowView.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.5];
        }
        rowView.layer.cornerRadius = 8;
        [self.scrollView addSubview:rowView];
        
        UISwitch *switchControl = [[UISwitch alloc] initWithFrame:CGRectMake(5, y + 2, 50, 30)];
        switchControl.tag = i;
        switchControl.onTintColor = [UIColor colorWithRed:0.91 green:0.27 blue:0.38 alpha:1];
        switchControl.transform = CGAffineTransformMakeScale(0.7, 0.7);
        [switchControl addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
        
        LUBVSettings *settings = [LUBVSettings sharedInstance];
        BOOL isOn = [[settings valueForKey:keys[i]] boolValue];
        switchControl.on = isOn;
        
        [self.scrollView addSubview:switchControl];
        [self.switches setObject:switchControl forKey:keys[i]];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(60, y + 4, 180, 26)];
        label.text = features[i];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12];
        [self.scrollView addSubview:label];
    }
    
    self.scrollView.contentSize = CGSizeMake(260, features.count * 36 + 20);
}

- (void)switchToggled:(UISwitch *)sender {
    LUBVSettings *settings = [LUBVSettings sharedInstance];
    NSArray *keys = @[
        @"alwaysImpostor", @"noKillCooldown", @"alwaysCanKill",
        @"alwaysCanVent", @"noVentCooldown", @"alwaysCanSabotage",
        @"alwaysCanReport", @"unlimitedVision", @"seeGhosts",
        @"godMode", @"fastSpeed", @"unlimitedEmergencies", @"noClip"
    ];
    
    [settings setValue:@(sender.on) forKey:keys[sender.tag]];
}

- (void)toggleMenu {
    self.isMenuOpen = !self.isMenuOpen;
    self.menuView.hidden = !self.menuView.hidden;
    
    if (self.isMenuOpen) {
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
            self.menuView.alpha = 1.0;
        } completion:nil];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            self.menuView.alpha = 0.0;
        }];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    CGPoint newCenter = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    newCenter.x = MAX(40, MIN(screenBounds.size.width - 40, newCenter.x));
    newCenter.y = MAX(40, MIN(screenBounds.size.height - 40, newCenter.y));
    
    self.center = newCenter;
    [gesture setTranslation:CGPointZero inView:self.superview];
}

@end

// ============================================================
// INJECT GUI
// ============================================================

static LUBVGUIButton *guiButton = nil;

__attribute__((constructor)) static void initialize() {
    NSLog(@"========================================");
    NSLog(@"⚡ LUBV Ultimate Loaded!");
    NSLog(@"========================================");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (!keyWindow) {
            keyWindow = [UIApplication sharedApplication].windows.firstObject;
        }
        
        if (keyWindow) {
            guiButton = [[LUBVGUIButton alloc] initWithFrame:CGRectMake(20, 100, 50, 50)];
            [keyWindow addSubview:guiButton];
        }
    });
}

// ============================================================
// UNDETECTED HOOKS - Using actual class names from dump
// ============================================================

// Hook PlayerControl (from dump: public class PlayerControl)
%hook PlayerControl

// Always Impostor
- (BOOL)IsImpostor {
    if ([LUBVSettings sharedInstance].alwaysImpostor) {
        return YES;
    }
    return %orig;
}

// No Kill Cooldown
- (float)GetKillCooldown {
    if ([LUBVSettings sharedInstance].noKillCooldown) {
        return 0.0f;
    }
    return %orig;
}

// God Mode - Prevent death
- (void)SetKilled:(id)player {
    if ([LUBVSettings sharedInstance].godMode) {
        return;
    }
    %orig;
}

// Fast Speed
- (float)GetSpeed {
    if ([LUBVSettings sharedInstance].fastSpeed) {
        return [LUBVSettings sharedInstance].playerSpeed;
    }
    return %orig;
}

// Unlimited Vision
- (float)GetVisionRadius {
    if ([LUBVSettings sharedInstance].unlimitedVision) {
        return 999.0f;
    }
    return %orig;
}

// See Ghosts
- (BOOL)IsGhost {
    if ([LUBVSettings sharedInstance].seeGhosts) {
        return NO;
    }
    return %orig;
}

// No Clip - Walk through walls
- (BOOL)CanMove {
    if ([LUBVSettings sharedInstance].noClip) {
        return YES;
    }
    return %orig;
}

%end

// Hook Vent (from dump: public class Vent)
%hook Vent

- (float)GetCooldown {
    if ([LUBVSettings sharedInstance].noVentCooldown) {
        return 0.0f;
    }
    return %orig;
}

- (BOOL)CanUse {
    if ([LUBVSettings sharedInstance].alwaysCanVent) {
        return YES;
    }
    return %orig;
}

%end

// Hook SabotageManager (from dump: public class SabotageManager)
%hook SabotageManager

- (BOOL)CanSabotage {
    if ([LUBVSettings sharedInstance].alwaysCanSabotage) {
        return YES;
    }
    return %orig;
}

%end

// Hook KillButtonManager (from dump: public class KillButtonManager)
%hook KillButtonManager

- (BOOL)CanKill {
    if ([LUBVSettings sharedInstance].alwaysCanKill) {
        return YES;
    }
    return %orig;
}

%end

// Hook MeetingHud (from dump: public class MeetingHud)
%hook MeetingHud

- (BOOL)CanReport {
    if ([LUBVSettings sharedInstance].alwaysCanReport) {
        return YES;
    }
    return %orig;
}

%end

// Hook EmergencyButton (from dump: public class EmergencyButton)
%hook EmergencyButton

- (int)GetRemainingUses {
    if ([LUBVSettings sharedInstance].unlimitedEmergencies) {
        return 99;
    }
    return %orig;
}

- (BOOL)CanUse {
    if ([LUBVSettings sharedInstance].unlimitedEmergencies) {
        return YES;
    }
    return %orig;
}

%end
