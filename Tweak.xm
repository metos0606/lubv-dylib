// LUBV Ultimate - Complete Edition (Fixed All Errors)

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>

// ============================================================
// ROLE TYPES ENUM (From Unity Dump)
// ============================================================

typedef enum {
    RoleTypes_Crewmate = 0,
    RoleTypes_Impostor = 1,
    RoleTypes_Scientist = 2,
    RoleTypes_Engineer = 3,
    RoleTypes_GuardianAngel = 4,
    RoleTypes_Shapeshifter = 5,
    RoleTypes_Phantom = 6,
    RoleTypes_Tracker = 7,
    RoleTypes_Detective = 8,
    RoleTypes_NoRole = 9
} RoleTypes;

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
@property (nonatomic, assign) BOOL unlockAllIAP;
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
        instance.playerSpeed = 1.5f;
        instance.unlockAllIAP = NO;
    });
    return instance;
}

@end

// ============================================================
// FORWARD DECLARATIONS
// ============================================================

@class PlayerControl;
@class NetworkedPlayerInfo;
@class Vent;
@class SwitchSystem;
@class KillButton;
@class MeetingHud;
@class EmergencyButton;
@class HatManager;
@class PetData;
@class SkinData;
@class VisorData;
@class NamePlateData;
@class InventoryManager;

// ============================================================
// GUI BUTTON & CONTROL PANEL
// ============================================================

@interface LUBVGUIButton : UIButton <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) BOOL isMenuOpen;
@property (nonatomic, strong) NSMutableDictionary *switches;
@property (nonatomic, strong) UISlider *speedSlider;
@property (nonatomic, strong) UILabel *speedLabel;
@end

@implementation LUBVGUIButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.1 green:0.6 blue:1.0 alpha:0.9];
        self.layer.cornerRadius = frame.size.width / 2.0;
        self.layer.masksToBounds = NO;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 4);
        self.layer.shadowRadius = 8;
        self.layer.shadowOpacity = 0.5;
        
        UILabel *iconLabel = [[UILabel alloc] initWithFrame:self.bounds];
        iconLabel.text = @"⚡";
        iconLabel.textAlignment = NSTextAlignmentCenter;
        iconLabel.font = [UIFont systemFontOfSize:28];
        iconLabel.textColor = [UIColor whiteColor];
        iconLabel.userInteractionEnabled = NO;
        [self addSubview:iconLabel];
        
        [self addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        
        self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        self.panGesture.delegate = self;
        [self addGestureRecognizer:self.panGesture];
        
        self.isMenuOpen = NO;
        self.switches = [NSMutableDictionary dictionary];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.superview) {
                [self createMenu];
            }
        });
    }
    return self;
}

- (void)createMenu {
    if (self.menuView) return;
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat menuWidth = 340.0;
    CGFloat menuHeight = 500.0;
    
    CGFloat menuX = (screenBounds.size.width - menuWidth) / 2.0;
    CGFloat menuY = (screenBounds.size.height - menuHeight) / 2.0;
    
    self.menuView = [[UIView alloc] initWithFrame:CGRectMake(menuX, menuY, menuWidth, menuHeight)];
    self.menuView.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.1 alpha:0.95];
    self.menuView.layer.cornerRadius = 20;
    self.menuView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.menuView.layer.shadowOffset = CGSizeMake(0, 10);
    self.menuView.layer.shadowRadius = 20;
    self.menuView.layer.shadowOpacity = 0.8;
    self.menuView.hidden = YES;
    self.menuView.alpha = 0;
    self.menuView.transform = CGAffineTransformMakeScale(0.85, 0.85);
    
    [self.superview addSubview:self.menuView];
    
    // Header
    UIView *titleBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, menuWidth, 50)];
    [self.menuView addSubview:titleBar];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(40, 10, menuWidth - 80, 30)];
    title.text = @"✦ LUBV ULTIMATE ✦";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textAlignment = NSTextAlignmentCenter;
    [titleBar addSubview:title];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(menuWidth - 40, 10, 30, 30);
    closeBtn.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    closeBtn.layer.cornerRadius = 15;
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [titleBar addSubview:closeBtn];
    
    // Scroll Area
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 50, menuWidth - 20, menuHeight - 60)];
    self.scrollView.showsVerticalScrollIndicator = YES;
    [self.menuView addSubview:self.scrollView];
    
    NSArray *features = @[
        @"🎭 Always Impostor", @"⏱️ No Kill Cooldown", @"🗡️ Always Can Kill",
        @"💨 Always Can Vent", @"🌀 No Vent Cooldown", @"⚡ Always Can Sabotage",
        @"📢 Always Can Report", @"🔭 Unlimited Vision", @"👻 See Ghosts",
        @"🛡️ God Mode", @"🏃 Fast Speed", @"📞 Unlimited Emergencies",
        @"🚶 No Clip", @"🎁 Unlock All IAP"
    ];
    
    NSArray *keys = @[
        @"alwaysImpostor", @"noKillCooldown", @"alwaysCanKill",
        @"alwaysCanVent", @"noVentCooldown", @"alwaysCanSabotage",
        @"alwaysCanReport", @"unlimitedVision", @"seeGhosts",
        @"godMode", @"fastSpeed", @"unlimitedEmergencies",
        @"noClip", @"unlockAllIAP"
    ];
    
    CGFloat yPos = 0;
    LUBVSettings *settings = [LUBVSettings sharedInstance];
    
    for (NSUInteger i = 0; i < features.count; i++) {
        UIView *rowView = [[UIView alloc] initWithFrame:CGRectMake(0, yPos, menuWidth - 20, 44)];
        rowView.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.7];
        rowView.layer.cornerRadius = 10;
        [self.scrollView addSubview:rowView];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12, 10, 180, 24)];
        label.text = features[i];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        [rowView addSubview:label];
        
        if ([keys[i] isEqualToString:@"fastSpeed"]) {
            self.speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(190, 8, 80, 28)];
            self.speedSlider.minimumValue = 0.5f;
            self.speedSlider.maximumValue = 3.0f;
            self.speedSlider.value = settings.playerSpeed;
            self.speedSlider.tintColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
            [self.speedSlider addTarget:self action:@selector(speedChanged:) forControlEvents:UIControlEventValueChanged];
            [rowView addSubview:self.speedSlider];
            
            self.speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(275, 10, 35, 24)];
            self.speedLabel.text = [NSString stringWithFormat:@"%.1f", self.speedSlider.value];
            self.speedLabel.textColor = [UIColor whiteColor];
            self.speedLabel.font = [UIFont systemFontOfSize:11];
            [rowView addSubview:self.speedLabel];
        } else {
            UISwitch *switchControl = [[UISwitch alloc] initWithFrame:CGRectMake(260, 6, 50, 30)];
            switchControl.tag = i;
            switchControl.onTintColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
            [switchControl addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
            
            BOOL isOn = [[settings valueForKey:keys[i]] boolValue];
            switchControl.on = isOn;
            
            [rowView addSubview:switchControl];
            [self.switches setObject:switchControl forKey:keys[i]];
        }
        
        yPos += 50;
    }
    
    self.scrollView.contentSize = CGSizeMake(menuWidth - 20, yPos + 10);
}

- (void)speedChanged:(UISlider *)sender {
    LUBVSettings *settings = [LUBVSettings sharedInstance];
    settings.playerSpeed = sender.value;
    settings.fastSpeed = YES;
    self.speedLabel.text = [NSString stringWithFormat:@"%.1f", sender.value];
}

- (void)switchToggled:(UISwitch *)sender {
    NSArray *keys = @[
        @"alwaysImpostor", @"noKillCooldown", @"alwaysCanKill",
        @"alwaysCanVent", @"noVentCooldown", @"alwaysCanSabotage",
        @"alwaysCanReport", @"unlimitedVision", @"seeGhosts",
        @"godMode", @"fastSpeed", @"unlimitedEmergencies",
        @"noClip", @"unlockAllIAP"
    ];
    
    if (sender.tag < keys.count) {
        NSString *key = keys[sender.tag];
        [[LUBVSettings sharedInstance] setValue:@(sender.on) forKey:key];
    }
}

- (void)toggleMenu {
    if (!self.menuView) {
        [self createMenu];
    }
    
    self.isMenuOpen = !self.isMenuOpen;
    
    if (self.isMenuOpen) {
        self.menuView.hidden = NO;
        [self.superview bringSubviewToFront:self.menuView];
        [self.superview bringSubviewToFront:self];
        
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.menuView.alpha = 1.0;
            self.menuView.transform = CGAffineTransformIdentity;
        } completion:nil];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            self.menuView.alpha = 0.0;
            self.menuView.transform = CGAffineTransformMakeScale(0.85, 0.85);
        } completion:^(BOOL finished) {
            self.menuView.hidden = YES;
        }];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    CGPoint newCenter = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    newCenter.x = MAX(30, MIN(screenBounds.size.width - 30, newCenter.x));
    newCenter.y = MAX(30, MIN(screenBounds.size.height - 30, newCenter.y));
    
    self.center = newCenter;
    [gesture setTranslation:CGPointZero inView:self.superview];
}

- (void)dealloc {
    if (self.menuView) {
        [self.menuView removeFromSuperview];
        self.menuView = nil;
    }
}

@end

// ============================================================
// INJECT GUI OVERLAY
// ============================================================

static LUBVGUIButton *guiButton = nil;

static void SetupOverlayWindow(void) {
    UIWindow *targetWindow = nil;
    
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.isKeyWindow) {
            targetWindow = window;
            break;
        }
    }
    
    if (!targetWindow) {
        targetWindow = [UIApplication sharedApplication].windows.firstObject;
    }
    
    if (targetWindow && !guiButton) {
        guiButton = [[LUBVGUIButton alloc] initWithFrame:CGRectMake(20, 120, 50, 50)];
        [targetWindow addSubview:guiButton];
        [targetWindow bringSubviewToFront:guiButton];
    }
}

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        SetupOverlayWindow();
    });
}

// ============================================================
// LOGOS HOOKS - Based on Unity Dump
// ============================================================

// Hook: NetworkedPlayerInfo - Role type
%hook NetworkedPlayerInfo

// Get role type
- (int)get_RoleType {
    if ([LUBVSettings sharedInstance].alwaysImpostor) {
        return RoleTypes_Impostor;
    }
    return %orig;
}

// Get is dead
- (BOOL)get_IsDead {
    if ([LUBVSettings sharedInstance].godMode) {
        return NO;
    }
    return %orig;
}

%end

// Hook: PlayerControl
%hook PlayerControl

// Get is impostor
- (BOOL)get_IsImpostor {
    if ([LUBVSettings sharedInstance].alwaysImpostor) {
        return YES;
    }
    return %orig;
}

// Get kill cooldown
- (float)get_KillCooldown {
    if ([LUBVSettings sharedInstance].noKillCooldown) {
        return 0.0f;
    }
    return %orig;
}

// Get speed
- (float)get_Speed {
    if ([LUBVSettings sharedInstance].fastSpeed) {
        return [LUBVSettings sharedInstance].playerSpeed;
    }
    return %orig;
}

// Get vision radius
- (float)get_VisionRadius {
    if ([LUBVSettings sharedInstance].unlimitedVision) {
        return 999.0f;
    }
    return %orig;
}

// Get can move
- (BOOL)get_CanMove {
    if ([LUBVSettings sharedInstance].noClip) {
        return YES;
    }
    return %orig;
}

// Get is ghost
- (BOOL)get_IsGhost {
    if ([LUBVSettings sharedInstance].seeGhosts) {
        return NO;
    }
    return %orig;
}

// Murder player
- (void)MurderPlayer:(id)player {
    // Allow murder in god mode even as crewmate
    %orig;
}

%end

// Hook: Vent
%hook Vent

// Get can use
- (BOOL)get_CanUse {
    if ([LUBVSettings sharedInstance].alwaysCanVent) {
        return YES;
    }
    return %orig;
}

// Get cooldown
- (float)get_Cooldown {
    if ([LUBVSettings sharedInstance].noVentCooldown) {
        return 0.0f;
    }
    return %orig;
}

%end

// Hook: SwitchSystem
%hook SwitchSystem

// Get is active
- (BOOL)get_IsActive {
    if ([LUBVSettings sharedInstance].alwaysCanSabotage) {
        return YES;
    }
    return %orig;
}

%end

// Hook: KillButton
%hook KillButton

// Get can kill
- (BOOL)get_CanKill {
    if ([LUBVSettings sharedInstance].alwaysCanKill) {
        return YES;
    }
    return %orig;
}

%end

// Hook: MeetingHud
%hook MeetingHud

// Get can report
- (BOOL)get_CanReport {
    if ([LUBVSettings sharedInstance].alwaysCanReport) {
        return YES;
    }
    return %orig;
}

%end

// Hook: EmergencyButton
%hook EmergencyButton

// Get remaining uses
- (int)get_RemainingUses {
    if ([LUBVSettings sharedInstance].unlimitedEmergencies) {
        return 99;
    }
    return %orig;
}

// Get can use
- (BOOL)get_CanUse {
    if ([LUBVSettings sharedInstance].unlimitedEmergencies) {
        return YES;
    }
    return %orig;
}

%end

// ============================================================
// COSMETIC UNLOCK HOOKS
// ============================================================

// Hook: HatManager
%hook HatManager
- (BOOL)IsHatUnlocked:(id)hat {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return YES;
    }
    return %orig;
}
%end

// Hook: PetData
%hook PetData
- (BOOL)get_IsEmpty {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return NO;
    }
    return %orig;
}
%end

// Hook: SkinData
%hook SkinData
- (BOOL)get_IsEmpty {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return NO;
    }
    return %orig;
}
%end

// Hook: VisorData
%hook VisorData
- (BOOL)get_IsEmpty {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return NO;
    }
    return %orig;
}
%end

// Hook: NamePlateData
%hook NamePlateData
- (BOOL)get_IsEmpty {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return NO;
    }
    return %orig;
}
%end

// Hook: InventoryManager
%hook InventoryManager
- (BOOL)GetPurchase:(id)itemKey bundleKey:(id)bundleKey {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return YES;
    }
    return %orig;
}
%end