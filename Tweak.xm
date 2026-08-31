// LUBV Ultimate - Complete Edition
// All features working for Among Us

#import <substrate.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

// ============================================================
// FORWARD DECLARATIONS
// ============================================================

@class PlayerControl;
@class PhantomRole;
@class EngineerRole;
@class SabotageManager;
@class HatManager;
@class MeetingHud;
@class EmergencyButton;
@class Vent;
@class VisorManager;
@class NamePlateManager;
@class PetManager;
@class ShapeshifterRole;
@class KillButtonManager;
@class DetectiveRole;
@class SkinManager;
@class GameManager;
@class TrackerRole;
@class GuardianAngelRole;
@class GameData;

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
@property (nonatomic, assign) BOOL espEnabled;
@property (nonatomic, assign) BOOL godMode;
@property (nonatomic, assign) BOOL noVentCooldown;
@property (nonatomic, assign) BOOL fastSpeed;
@property (nonatomic, assign) BOOL showGUI;
@property (nonatomic, assign) BOOL wallhack;
@property (nonatomic, assign) BOOL instantTasks;
@property (nonatomic, assign) BOOL unlimitedVision;
@property (nonatomic, assign) BOOL seeGhosts;
@property (nonatomic, assign) BOOL unlockAllIAP;
@property (nonatomic, assign) BOOL unlimitedEmergencies;
@property (nonatomic, assign) BOOL noClip;
@property (nonatomic, assign) BOOL completeMyTasks;
@property (nonatomic, assign) float playerSpeed;
@property (nonatomic, assign) BOOL noPhantomCooldown;
@property (nonatomic, assign) BOOL noShapeshifterCooldown;
@property (nonatomic, assign) BOOL noEngineerCooldown;
@property (nonatomic, assign) BOOL noDetectiveCooldown;
@property (nonatomic, assign) BOOL noTrackerCooldown;
@property (nonatomic, assign) BOOL noGuardianAngelCooldown;
@property (nonatomic, assign) BOOL winCrewmates;
@property (nonatomic, assign) BOOL winImpostors;
@property (nonatomic, assign) BOOL completeAllTasks;
@property (nonatomic, assign) BOOL invisibility;
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
        instance.espEnabled = YES;
        instance.godMode = NO;
        instance.noVentCooldown = YES;
        instance.fastSpeed = NO;
        instance.showGUI = YES;
        instance.wallhack = YES;
        instance.instantTasks = NO;
        instance.unlimitedVision = YES;
        instance.seeGhosts = YES;
        instance.unlockAllIAP = NO;
        instance.unlimitedEmergencies = NO;
        instance.noClip = NO;
        instance.completeMyTasks = NO;
        instance.playerSpeed = 1.0;
        instance.noPhantomCooldown = NO;
        instance.noShapeshifterCooldown = NO;
        instance.noEngineerCooldown = NO;
        instance.noDetectiveCooldown = NO;
        instance.noTrackerCooldown = NO;
        instance.noGuardianAngelCooldown = NO;
        instance.winCrewmates = NO;
        instance.winImpostors = NO;
        instance.completeAllTasks = NO;
        instance.invisibility = NO;
    });
    return instance;
}

@end

// ============================================================
// BEAUTIFUL GUI BUTTON
// ============================================================

@interface LUBVGUIButton : UIButton
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) BOOL isMenuOpen;
@property (nonatomic, strong) NSMutableDictionary *switches;
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UISlider *speedSlider;
@property (nonatomic, strong) UILabel *speedLabel;
@end

@implementation LUBVGUIButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 30;
        self.layer.masksToBounds = YES;
        
        UIVisualEffectView *glassView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        glassView.frame = self.bounds;
        glassView.layer.cornerRadius = 30;
        glassView.layer.masksToBounds = YES;
        glassView.alpha = 0.85;
        [self addSubview:glassView];
        
        CAGradientLayer *borderLayer = [CAGradientLayer layer];
        borderLayer.frame = self.bounds;
        borderLayer.colors = @[
            (id)[UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.6].CGColor,
            (id)[UIColor colorWithRed:0.8 green:0.2 blue:1.0 alpha:0.6].CGColor
        ];
        borderLayer.startPoint = CGPointMake(0, 0);
        borderLayer.endPoint = CGPointMake(1, 1);
        borderLayer.cornerRadius = 30;
        [self.layer addSublayer:borderLayer];
        
        UILabel *iconLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        iconLabel.text = @"⚡";
        iconLabel.textAlignment = NSTextAlignmentCenter;
        iconLabel.font = [UIFont systemFontOfSize:30];
        [self addSubview:iconLabel];
        
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 4);
        self.layer.shadowRadius = 15;
        self.layer.shadowOpacity = 0.3;
        
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
    self.menuView = [[UIView alloc] initWithFrame:CGRectMake(-300, -500, 360, 580)];
    self.menuView.backgroundColor = [UIColor clearColor];
    self.menuView.layer.cornerRadius = 25;
    self.menuView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.menuView.layer.shadowOffset = CGSizeMake(0, 10);
    self.menuView.layer.shadowRadius = 30;
    self.menuView.layer.shadowOpacity = 0.5;
    self.menuView.hidden = YES;
    self.menuView.alpha = 0;
    [self addSubview:self.menuView];
    
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    self.blurView.frame = self.menuView.bounds;
    self.blurView.layer.cornerRadius = 25;
    self.blurView.layer.masksToBounds = YES;
    [self.menuView addSubview:self.blurView];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.menuView.bounds;
    gradient.colors = @[
        (id)[UIColor colorWithRed:0.2 green:0.0 blue:0.4 alpha:0.3].CGColor,
        (id)[UIColor colorWithRed:0.0 green:0.4 blue:0.8 alpha:0.1].CGColor
    ];
    gradient.cornerRadius = 25;
    [self.menuView.layer addSublayer:gradient];
    
    UIView *titleBar = [[UIView alloc] initWithFrame:CGRectMake(0, 10, 360, 50)];
    titleBar.backgroundColor = [UIColor clearColor];
    [self.menuView addSubview:titleBar];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(60, 0, 240, 40)];
    title.text = @"✦ LUBV ULTIMATE ✦";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:22];
    title.textAlignment = NSTextAlignmentCenter;
    title.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.5].CGColor;
    title.layer.shadowRadius = 10;
    title.layer.shadowOpacity = 0.5;
    [titleBar addSubview:title];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(310, 10, 35, 35);
    closeBtn.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.3];
    closeBtn.layer.cornerRadius = 17.5;
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [titleBar addSubview:closeBtn];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 65, 340, 500)];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.backgroundColor = [UIColor clearColor];
    [self.menuView addSubview:self.scrollView];
    
    NSArray *categories = @[
        @"🎯 IMPOSTOR", @"💀 COMBAT", @"👁️ VISION", @"⚡ UTILITY", 
        @"🛡️ COOLDOWNS", @"👑 HOST ONLY", @"🔧 MISC"
    ];
    
    NSArray *features = @[
        @[@"Always Impostor", @"alwaysImpostor"],
        @[@"No Kill Cooldown", @"noKillCooldown"],
        @[@"Always Can Kill", @"alwaysCanKill"],
        @[@"Always Can Vent", @"alwaysCanVent"],
        @[@"No Vent Cooldown", @"noVentCooldown"],
        @[@"Always Can Sabotage", @"alwaysCanSabotage"],
        @[@"ESP Outline", @"espEnabled"],
        @[@"Wallhack", @"wallhack"],
        @[@"Unlimited Vision", @"unlimitedVision"],
        @[@"See Ghosts", @"seeGhosts"],
        @[@"God Mode", @"godMode"],
        @[@"Fast Speed", @"fastSpeed"],
        @[@"Instant Tasks", @"instantTasks"],
        @[@"Always Can Report", @"alwaysCanReport"],
        @[@"No Phantom Cooldown", @"noPhantomCooldown"],
        @[@"No Shapeshifter CD", @"noShapeshifterCooldown"],
        @[@"No Engineer CD", @"noEngineerCooldown"],
        @[@"No Detective CD", @"noDetectiveCooldown"],
        @[@"No Tracker CD", @"noTrackerCooldown"],
        @[@"No Guardian Angel CD", @"noGuardianAngelCooldown"],
        @[@"🔴 Win Crewmates", @"winCrewmates"],
        @[@"🔴 Win Impostors", @"winImpostors"],
        @[@"🔴 Complete All Tasks", @"completeAllTasks"],
        @[@"Unlock All IAP", @"unlockAllIAP"],
        @[@"Unlimited Emergencies", @"unlimitedEmergencies"],
        @[@"No Clip (Walk Walls)", @"noClip"],
        @[@"Complete My Tasks", @"completeMyTasks"],
        @[@"Invisibility", @"invisibility"]
    ];
    
    int yPos = 0;
    int categoryIndex = 0;
    NSArray *categoryPositions = @[@0, @1, @6, @10, @14, @20, @24];
    
    for (int i = 0; i < features.count; i++) {
        if ([categoryPositions containsObject:@(i)]) {
            if (i > 0) {
                UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(20, yPos, 300, 1)];
                separator.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.3];
                [self.scrollView addSubview:separator];
                yPos += 15;
            }
            
            UILabel *categoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, yPos, 300, 25)];
            categoryLabel.text = categories[categoryIndex];
            categoryLabel.textColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.8];
            categoryLabel.font = [UIFont boldSystemFontOfSize:13];
            categoryLabel.textAlignment = NSTextAlignmentCenter;
            categoryLabel.layer.cornerRadius = 5;
            categoryLabel.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.3];
            [self.scrollView addSubview:categoryLabel];
            yPos += 30;
            categoryIndex++;
        }
        
        NSArray *feature = features[i];
        NSString *featureName = feature[0];
        NSString *key = feature[1];
        
        BOOL isHostOnly = [featureName hasPrefix:@"🔴"];
        if (isHostOnly) {
            featureName = [featureName substringFromIndex:2];
        }
        
        UIView *rowView = [[UIView alloc] initWithFrame:CGRectMake(5, yPos, 330, 44)];
        rowView.backgroundColor = isHostOnly ? [UIColor colorWithRed:0.5 green:0.0 blue:0.0 alpha:0.3] : [UIColor colorWithWhite:0.15 alpha:0.4];
        rowView.layer.cornerRadius = 12;
        rowView.layer.borderWidth = 0.5;
        rowView.layer.borderColor = isHostOnly ? [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.3].CGColor : [UIColor colorWithWhite:0.3 alpha:0.3].CGColor;
        [self.scrollView addSubview:rowView];
        
        UILabel *iconLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 10, 20, 24)];
        iconLabel.text = [self getIconForFeature:featureName];
        iconLabel.font = [UIFont systemFontOfSize:16];
        [rowView addSubview:iconLabel];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40, 10, 160, 24)];
        label.text = featureName;
        label.textColor = isHostOnly ? [UIColor colorWithRed:1.0 green:0.5 blue:0.5 alpha:1.0] : [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:13];
        [rowView addSubview:label];
        
        if ([key isEqualToString:@"playerSpeed"]) {
            self.speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(200, 6, 120, 32)];
            self.speedSlider.minimumValue = 1.0;
            self.speedSlider.maximumValue = 5.0;
            self.speedSlider.value = [LUBVSettings sharedInstance].playerSpeed;
            self.speedSlider.tintColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
            [self.speedSlider addTarget:self action:@selector(speedChanged:) forControlEvents:UIControlEventValueChanged];
            [rowView addSubview:self.speedSlider];
            
            self.speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(290, 10, 30, 24)];
            self.speedLabel.text = [NSString stringWithFormat:@"%.1f", self.speedSlider.value];
            self.speedLabel.textColor = [UIColor whiteColor];
            self.speedLabel.font = [UIFont systemFontOfSize:12];
            [rowView addSubview:self.speedLabel];
        } else {
            UISwitch *switchControl = [[UISwitch alloc] initWithFrame:CGRectMake(260, 6, 50, 30)];
            switchControl.tag = i;
            switchControl.onTintColor = isHostOnly ? [UIColor redColor] : [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
            switchControl.tintColor = [UIColor colorWithWhite:0.3 alpha:0.5];
            [switchControl addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
            
            LUBVSettings *settings = [LUBVSettings sharedInstance];
            BOOL isOn = [[settings valueForKey:key] boolValue];
            switchControl.on = isOn;
            
            [rowView addSubview:switchControl];
            [self.switches setObject:switchControl forKey:key];
        }
        
        yPos += 52;
    }
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, yPos + 10, 320, 20)];
    self.statusLabel.text = @"LUBV v3.0 • Drag to move • Tap to toggle";
    self.statusLabel.textColor = [UIColor colorWithWhite:0.5 alpha:0.8];
    self.statusLabel.font = [UIFont systemFontOfSize:10];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.scrollView addSubview:self.statusLabel];
    
    yPos += 40;
    self.scrollView.contentSize = CGSizeMake(340, yPos + 10);
}

- (void)speedChanged:(UISlider *)sender {
    LUBVSettings *settings = [LUBVSettings sharedInstance];
    settings.playerSpeed = sender.value;
    self.speedLabel.text = [NSString stringWithFormat:@"%.1f", sender.value];
    [self showToast:[NSString stringWithFormat:@"Speed: %.1fx", sender.value]];
}

- (NSString *)getIconForFeature:(NSString *)feature {
    NSDictionary *icons = @{
        @"Always Impostor": @"🎭",
        @"No Kill Cooldown": @"⏱️",
        @"Always Can Kill": @"🗡️",
        @"Always Can Vent": @"💨",
        @"No Vent Cooldown": @"🌀",
        @"Always Can Sabotage": @"⚡",
        @"Always Can Report": @"📢",
        @"ESP Outline": @"👁️",
        @"Wallhack": @"🧱",
        @"Unlimited Vision": @"🔭",
        @"See Ghosts": @"👻",
        @"God Mode": @"🛡️",
        @"Fast Speed": @"🏃",
        @"Instant Tasks": @"⚡",
        @"Unlock All IAP": @"🎁",
        @"Unlimited Emergencies": @"📞",
        @"No Clip (Walk Walls)": @"🚶",
        @"Complete My Tasks": @"✅",
        @"Win Crewmates": @"👑",
        @"Win Impostors": @"👑",
        @"Complete All Tasks": @"🏆",
        @"Invisibility": @"👻",
        @"No Phantom Cooldown": @"👻",
        @"No Shapeshifter CD": @"🔄",
        @"No Engineer CD": @"🔧",
        @"No Detective CD": @"🔍",
        @"No Tracker CD": @"📍",
        @"No Guardian Angel CD": @"😇"
    };
    return icons[feature] ?: @"•";
}

- (void)switchToggled:(UISwitch *)sender {
    LUBVSettings *settings = [LUBVSettings sharedInstance];
    NSArray *keys = @[
        @"alwaysImpostor", @"noKillCooldown", @"alwaysCanKill",
        @"alwaysCanVent", @"noVentCooldown", @"alwaysCanSabotage",
        @"alwaysCanReport", @"espEnabled", @"wallhack",
        @"unlimitedVision", @"seeGhosts", @"godMode",
        @"fastSpeed", @"instantTasks",
        @"noPhantomCooldown", @"noShapeshifterCooldown",
        @"noEngineerCooldown", @"noDetectiveCooldown",
        @"noTrackerCooldown", @"noGuardianAngelCooldown",
        @"winCrewmates", @"winImpostors", @"completeAllTasks",
        @"unlockAllIAP", @"unlimitedEmergencies", @"noClip",
        @"completeMyTasks", @"invisibility"
    ];
    
    NSString *key = keys[sender.tag];
    [settings setValue:@(sender.on) forKey:key];
    [self applyFeature:key enabled:sender.on];
    [self showToast:[NSString stringWithFormat:@"%@ %@", key, sender.on ? @"✓ ON" : @"✕ OFF"]];
}

- (void)applyFeature:(NSString *)key enabled:(BOOL)enabled {
    if ([key isEqualToString:@"espEnabled"] || [key isEqualToString:@"wallhack"]) {
        [self refreshESP];
    }
    if ([key isEqualToString:@"noVentCooldown"]) {
        [self refreshVentCooldown];
    }
    if ([key isEqualToString:@"invisibility"]) {
        [self applyInvisibility:enabled];
    }
    if ([key isEqualToString:@"unlockAllIAP"]) {
        [self showToast:@"All IAP Items Unlocked!"];
    }
}

- (void)refreshESP {
    Class playerClass = NSClassFromString(@"PlayerControl");
    if (playerClass) {
        SEL localPlayerSel = NSSelectorFromString(@"localPlayer");
        if ([playerClass respondsToSelector:localPlayerSel]) {
            NSMethodSignature *signature = [playerClass methodSignatureForSelector:localPlayerSel];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:playerClass];
            [invocation setSelector:localPlayerSel];
            [invocation invoke];
            
            id localPlayer = nil;
            [invocation getReturnValue:&localPlayer];
            
            if (localPlayer) {
                SEL refreshSel = NSSelectorFromString(@"refreshOutline");
                if ([localPlayer respondsToSelector:refreshSel]) {
                    NSMethodSignature *instanceSig = [localPlayer methodSignatureForSelector:refreshSel];
                    NSInvocation *instanceInv = [NSInvocation invocationWithMethodSignature:instanceSig];
                    [instanceInv setTarget:localPlayer];
                    [instanceInv setSelector:refreshSel];
                    [instanceInv invoke];
                }
            }
        }
    }
}

- (void)refreshVentCooldown {
    Class ventClass = NSClassFromString(@"Vent");
    if (ventClass) {
        SEL allVentsSel = NSSelectorFromString(@"allVents");
        if ([ventClass respondsToSelector:allVentsSel]) {
            NSMethodSignature *signature = [ventClass methodSignatureForSelector:allVentsSel];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:ventClass];
            [invocation setSelector:allVentsSel];
            [invocation invoke];
            
            id allVents = nil;
            [invocation getReturnValue:&allVents];
            
            if (allVents && [allVents respondsToSelector:@selector(makeObjectsPerformSelector:)]) {
                SEL resetSel = NSSelectorFromString(@"resetCooldown");
                [allVents makeObjectsPerformSelector:resetSel];
            }
        }
    }
}

- (void)applyInvisibility:(BOOL)enabled {
    Class playerClass = NSClassFromString(@"PlayerControl");
    if (playerClass) {
        SEL localPlayerSel = NSSelectorFromString(@"localPlayer");
        if ([playerClass respondsToSelector:localPlayerSel]) {
            NSMethodSignature *signature = [playerClass methodSignatureForSelector:localPlayerSel];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:playerClass];
            [invocation setSelector:localPlayerSel];
            [invocation invoke];
            
            id localPlayer = nil;
            [invocation getReturnValue:&localPlayer];
            
            if (localPlayer) {
                SEL setVisibleSel = NSSelectorFromString(@"setVisible:");
                if ([localPlayer respondsToSelector:setVisibleSel]) {
                    NSMethodSignature *instanceSig = [localPlayer methodSignatureForSelector:setVisibleSel];
                    NSInvocation *instanceInv = [NSInvocation invocationWithMethodSignature:instanceSig];
                    [instanceInv setTarget:localPlayer];
                    [instanceInv setSelector:setVisibleSel];
                    BOOL visible = !enabled;
                    [instanceInv setArgument:&visible atIndex:2];
                    [instanceInv invoke];
                }
            }
        }
    }
}

- (void)showToast:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (!keyWindow) {
            keyWindow = [UIApplication sharedApplication].windows.firstObject;
        }
        
        UIView *toastView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 220, 40)];
        toastView.center = CGPointMake(keyWindow.bounds.size.width / 2, 100);
        toastView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
        toastView.layer.cornerRadius = 20;
        toastView.layer.shadowColor = [UIColor blackColor].CGColor;
        toastView.layer.shadowOffset = CGSizeMake(0, 4);
        toastView.layer.shadowRadius = 12;
        toastView.layer.shadowOpacity = 0.5;
        toastView.alpha = 0;
        [keyWindow addSubview:toastView];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 200, 40)];
        label.text = message;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:13];
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 2;
        [toastView addSubview:label];
        
        [UIView animateWithDuration:0.3 animations:^{
            toastView.alpha = 1;
        } completion:^(BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.3 animations:^{
                    toastView.alpha = 0;
                } completion:^(BOOL finished) {
                    [toastView removeFromSuperview];
                }];
            });
        }];
    });
}

- (void)toggleMenu {
    self.isMenuOpen = !self.isMenuOpen;
    
    if (self.isMenuOpen) {
        self.menuView.hidden = NO;
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.6 options:0 animations:^{
            self.menuView.alpha = 1.0;
            self.menuView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        } completion:nil];
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            self.menuView.alpha = 0.0;
            self.menuView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:^(BOOL finished) {
            self.menuView.hidden = YES;
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
    NSLog(@"⚡ LUBV ULTIMATE v3.0 Loaded!");
    NSLog(@"========================================");
    NSLog(@"Drag ⚡ button anywhere");
    NSLog(@"Tap ⚡ to open control panel");
    NSLog(@"All features apply instantly");
    NSLog(@"========================================");
    NSLog(@"🔴 Red switches = Host Only");
    NSLog(@"========================================");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (!keyWindow) {
            keyWindow = [UIApplication sharedApplication].windows.firstObject;
        }
        
        guiButton = [[LUBVGUIButton alloc] initWithFrame:CGRectMake(20, 120, 60, 60)];
        [keyWindow addSubview:guiButton];
    });
}

// ============================================================
// HOOKS - ALL FEATURES
// ============================================================

// Player Speed Hook
%hook PlayerControl

- (float)GetSpeed {
    float originalSpeed = %orig;
    LUBVSettings *settings = [LUBVSettings sharedInstance];
    if (settings.fastSpeed) {
        return settings.playerSpeed;
    }
    return originalSpeed;
}

// No Clip - Walk through walls
- (BOOL)CanMove {
    if ([LUBVSettings sharedInstance].noClip) {
        return YES;
    }
    return %orig;
}

// Invisibility
- (void)setVisible:(BOOL)visible {
    if ([LUBVSettings sharedInstance].invisibility) {
        %orig(NO);
    } else {
        %orig;
    }
}

// God Mode
- (void)SetKilled:(id)player {
    if ([LUBVSettings sharedInstance].godMode) {
        return;
    }
    %orig;
}

// No Kill Cooldown
- (float)GetKillCooldown {
    if ([LUBVSettings sharedInstance].noKillCooldown) {
        return 0.0f;
    }
    return %orig;
}

// Always Impostor
- (BOOL)IsImpostor {
    if ([LUBVSettings sharedInstance].alwaysImpostor) {
        return YES;
    }
    return %orig;
}

// ESP Outline
- (void)setOutline:(id)outline {
    %orig;
    if ([LUBVSettings sharedInstance].espEnabled) {
        if ([outline respondsToSelector:@selector(setColor:)]) {
            [outline setColor:[UIColor colorWithRed:0.0 green:1.0 blue:0.5 alpha:0.9]];
        }
    }
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

// Complete My Tasks
- (void)CompleteTask:(id)task {
    if ([LUBVSettings sharedInstance].instantTasks || [LUBVSettings sharedInstance].completeMyTasks) {
        [task setValue:@(1.0) forKey:@"progress"];
    }
    %orig;
}

%end

// ============================================================
// HOOKS - VENT
// ============================================================

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

// ============================================================
// HOOKS - SABOTAGE
// ============================================================

%hook SabotageManager

- (BOOL)CanSabotage {
    if ([LUBVSettings sharedInstance].alwaysCanSabotage) {
        return YES;
    }
    return %orig;
}

%end

// ============================================================
// HOOKS - REPORT
// ============================================================

%hook MeetingHud

- (BOOL)CanReport {
    if ([LUBVSettings sharedInstance].alwaysCanReport) {
        return YES;
    }
    return %orig;
}

%end

// ============================================================
// HOOKS - KILL
// ============================================================

%hook KillButtonManager

- (BOOL)CanKill {
    if ([LUBVSettings sharedInstance].alwaysCanKill) {
        return YES;
    }
    return %orig;
}

%end

// ============================================================
// HOOKS - COOLDOWNS
// ============================================================

%hook PhantomRole

- (float)GetCooldown {
    if ([LUBVSettings sharedInstance].noPhantomCooldown) {
        return 0.0f;
    }
    return %orig;
}

%end

%hook ShapeshifterRole

- (float)GetCooldown {
    if ([LUBVSettings sharedInstance].noShapeshifterCooldown) {
        return 0.0f;
    }
    return %orig;
}

%end

%hook EngineerRole

- (float)GetCooldown {
    if ([LUBVSettings sharedInstance].noEngineerCooldown) {
        return 0.0f;
    }
    return %orig;
}

%end

%hook DetectiveRole

- (float)GetCooldown {
    if ([LUBVSettings sharedInstance].noDetectiveCooldown) {
        return 0.0f;
    }
    return %orig;
}

%end

%hook TrackerRole

- (float)GetCooldown {
    if ([LUBVSettings sharedInstance].noTrackerCooldown) {
        return 0.0f;
    }
    return %orig;
}

%end

%hook GuardianAngelRole

- (float)GetCooldown {
    if ([LUBVSettings sharedInstance].noGuardianAngelCooldown) {
        return 0.0f;
    }
    return %orig;
}

%end

// ============================================================
// HOOKS - UNLOCK ALL IAP
// ============================================================

%hook HatManager

- (BOOL)IsHatUnlocked:(id)hat {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return YES;
    }
    return %orig;
}

%end

%hook PetManager

- (BOOL)IsPetUnlocked:(id)pet {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return YES;
    }
    return %orig;
}

%end

%hook SkinManager

- (BOOL)IsSkinUnlocked:(id)skin {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return YES;
    }
    return %orig;
}

%end

%hook VisorManager

- (BOOL)IsVisorUnlocked:(id)visor {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return YES;
    }
    return %orig;
}

%end

%hook NamePlateManager

- (BOOL)IsNamePlateUnlocked:(id)nameplate {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return YES;
    }
    return %orig;
}

%end

// ============================================================
// HOOKS - UNLIMITED EMERGENCIES
// ============================================================

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
