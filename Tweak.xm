//
//  Tweak.xm
//  Among Us iOS Cheat (FULLY FIXED + GUI)
//  
//  Features:
//  - Always Impostor
//  - All Cosmetics Unlocked
//  - ESP (Player positions, roles, names)
//  - Auto Win
//  - Anti-Ban features
//  - In-game settings menu with toggles
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <sys/mman.h>

// ============================================================
// MARK: - Configuration
// ============================================================

static BOOL g_alwaysImpostor = YES;
static BOOL g_unlockAllCosmetics = YES;
static BOOL g_espEnabled = YES;
static BOOL g_autoWinEnabled = NO;
static BOOL g_showAllPlayers = YES;
static BOOL g_noBanMode = YES;

// ============================================================
// MARK: - FORWARD DECLARATIONS (FIXED)
// ============================================================

// These must be declared BEFORE they're used in the constructor
static void updateESP(void);
static BOOL hooked_CanMakePurchases(id self, SEL sel);
static id hooked_GetProductInfo(id self, SEL sel, id productId);
static void hooked_OnPlayerSpawn(id self, SEL sel, id player);

// ============================================================
// MARK: - Memory Protection Helper
// ============================================================

static void enable_writing(void *ptr, size_t size) {
    uintptr_t page = (uintptr_t)ptr & ~(uintptr_t)(PAGE_SIZE - 1);
    mprotect((void *)page, size + ((uintptr_t)ptr - page), PROT_READ | PROT_WRITE | PROT_EXEC);
}

// ============================================================
// MARK: - Game State Tracking
// ============================================================

typedef struct {
    BOOL inGame;
    BOOL isImpostor;
    int myPlayerId;
    int playerCount;
    void *gameManager;
    void *shipStatus;
} GameState;

static GameState g_gameState = {0};

// ============================================================
// MARK: - Class Definitions for Runtime Hooking
// ============================================================

@interface PlayerControl : NSObject
@property (nonatomic, assign) int PlayerId;
@property (nonatomic, assign) BOOL IsImpostor;
@property (nonatomic, assign) BOOL IsDead;
@property (nonatomic, assign) BOOL IsDisconnected;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) int colorId;
@property (nonatomic, assign) void *myPhysics;
@end

@interface GameData : NSObject
@property (nonatomic, strong) NSArray *AllPlayers;
@property (nonatomic, assign) int TotalTasks;
@property (nonatomic, assign) int CompletedTasks;
+ (GameData *)Instance;
- (PlayerControl *)GetPlayerById:(int)playerId;
@end

@interface ShipStatus : NSObject
@property (nonatomic, assign) int MapId;
@property (nonatomic, assign) int NumImpostors;
@property (nonatomic, assign) int MaxPlayers;
@property (nonatomic, assign) BOOL GameEnded;
+ (ShipStatus *)Instance;
@end

@interface MeetingHud : NSObject
@property (nonatomic, assign) int state;
@property (nonatomic, strong) NSArray *playerStates;
- (void)Close;
- (void)SkipVote;
@end

@interface InnerNetClient : NSObject
- (void)SendRpc;
@property (nonatomic, assign) int ClientId;
+ (InnerNetClient *)Instance;
@end

// ============================================================
// MARK: - Settings Menu GUI
// ============================================================

@interface CheatSettingsViewController : UIViewController {
    UISwitch *impostorSwitch;
    UISwitch *cosmeticsSwitch;
    UISwitch *espSwitch;
    UISwitch *autoWinSwitch;
    UISwitch *antiBanSwitch;
    UILabel *statusLabel;
}
@end

@implementation CheatSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.95];
    self.title = @"Among Us Cheat Menu";
    
    // Navigation bar styling
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    self.navigationController.navigationBar.titleTextAttributes = @{
        NSForegroundColorAttributeName: [UIColor whiteColor],
        NSFontAttributeName: [UIFont boldSystemFontOfSize:20]
    };
    
    UIBarButtonItem *closeBtn = [[UIBarButtonItem alloc] initWithTitle:@"✕" 
                                                                 style:UIBarButtonItemStylePlain 
                                                                target:self 
                                                                action:@selector(closeTapped)];
    closeBtn.tintColor = [UIColor whiteColor];
    [closeBtn setTitleTextAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:24]} forState:UIControlStateNormal];
    self.navigationItem.leftBarButtonItem = closeBtn;
    
    UIBarButtonItem *applyBtn = [[UIBarButtonItem alloc] initWithTitle:@"Apply" 
                                                                 style:UIBarButtonItemStyleDone 
                                                                target:self 
                                                                action:@selector(applyTapped)];
    applyBtn.tintColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0];
    self.navigationItem.rightBarButtonItem = applyBtn;
    
    [self setupUI];
}

- (void)setupUI {
    UIView *container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    container.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    container.layer.cornerRadius = 16;
    container.layer.masksToBounds = YES;
    [self.view addSubview:container];
    
    // Scrollable content
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.showsVerticalScrollIndicator = YES;
    [container addSubview:scrollView];
    
    // Content stack
    UIStackView *stack = [[UIStackView alloc] init];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 16;
    stack.layoutMargins = UIEdgeInsetsMake(20, 20, 20, 20);
    stack.layoutMarginsRelativeArrangement = YES;
    [scrollView addSubview:stack];
    
    // Title label with icon
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"⚙️ Cheat Settings";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:22];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [stack addArrangedSubview:titleLabel];
    
    // Status label
    statusLabel = [[UILabel alloc] init];
    statusLabel.text = @"Status: Ready";
    statusLabel.textColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0];
    statusLabel.font = [UIFont systemFontOfSize:14];
    statusLabel.textAlignment = NSTextAlignmentCenter;
    [stack addArrangedSubview:statusLabel];
    
    // Separator
    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    separator.heightAnchor.constraintEqualToConstant:1.0).active = YES;
    [stack addArrangedSubview:separator];
    
    // Toggle: Always Impostor
    impostorSwitch = [self createToggleWithTitle:@"🔴 Always Impostor" 
                                       subtitle:@"You will always be the Impostor"
                                        default:g_alwaysImpostor];
    [stack addArrangedSubview:[self wrapToggle:impostorSwitch]];
    
    // Toggle: Unlock Cosmetics
    cosmeticsSwitch = [self createToggleWithTitle:@"👗 Unlock All Cosmetics" 
                                       subtitle:@"All hats, skins, pets, and visors unlocked"
                                        default:g_unlockAllCosmetics];
    [stack addArrangedSubview:[self wrapToggle:cosmeticsSwitch]];
    
    // Toggle: ESP
    espSwitch = [self createToggleWithTitle:@"👁️ ESP" 
                                  subtitle:@"Show player positions, roles, and names"
                                   default:g_espEnabled];
    [stack addArrangedSubview:[self wrapToggle:espSwitch]];
    
    // Toggle: Auto Win
    autoWinSwitch = [self createToggleWithTitle:@"🏆 Auto Win" 
                                      subtitle:@"Instantly win as Impostor"
                                       default:g_autoWinEnabled];
    [stack addArrangedSubview:[self wrapToggle:autoWinSwitch]];
    
    // Toggle: Anti-Ban
    antiBanSwitch = [self createToggleWithTitle:@"🛡️ Anti-Ban" 
                                      subtitle:@"Bypass anti-cheat detection"
                                       default:g_noBanMode];
    [stack addArrangedSubview:[self wrapToggle:antiBanSwitch]];
    
    // Separator
    UIView *separator2 = [[UIView alloc] init];
    separator2.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    separator2.heightAnchor.constraintEqualToConstant:1.0).active = YES;
    [stack addArrangedSubview:separator2];
    
    // Credits
    UILabel *creditsLabel = [[UILabel alloc] init];
    creditsLabel.text = @"Made with ❤️ for LO";
    creditsLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    creditsLabel.font = [UIFont systemFontOfSize:12];
    creditsLabel.textAlignment = NSTextAlignmentCenter;
    [stack addArrangedSubview:creditsLabel];
    
    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        [container.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [container.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20],
        [container.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20],
        [container.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20],
        
        [scrollView.topAnchor constraintEqualToAnchor:container.topAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
        
        [stack.topAnchor constraintEqualToAnchor:scrollView.topAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:scrollView.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:scrollView.trailingAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:scrollView.bottomAnchor],
        [stack.widthAnchor constraintEqualToAnchor:scrollView.widthAnchor],
    ]];
}

- (UISwitch *)createToggleWithTitle:(NSString *)title subtitle:(NSString *)subtitle default:(BOOL)defaultValue {
    UISwitch *toggle = [[UISwitch alloc] init];
    toggle.onTintColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0];
    toggle.tintColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    toggle.on = defaultValue;
    return toggle;
}

- (UIView *)wrapToggle:(UISwitch *)toggle {
    UIView *wrapper = [[UIView alloc] init];
    wrapper.translatesAutoresizingMaskIntoConstraints = NO;
    wrapper.backgroundColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    wrapper.layer.cornerRadius = 12;
    wrapper.layer.masksToBounds = YES;
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = toggle.accessibilityLabel ?: @"Toggle";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    
    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    subtitleLabel.text = toggle.accessibilityHint ?: @"";
    subtitleLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    subtitleLabel.font = [UIFont systemFontOfSize:12];
    subtitleLabel.numberOfLines = 0;
    
    UIStackView *textStack = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel, subtitleLabel]];
    textStack.translatesAutoresizingMaskIntoConstraints = NO;
    textStack.axis = UILayoutConstraintAxisVertical;
    textStack.spacing = 2;
    
    toggle.translatesAutoresizingMaskIntoConstraints = NO;
    
    [wrapper addSubview:textStack];
    [wrapper addSubview:toggle];
    
    [NSLayoutConstraint activateConstraints:@[
        [textStack.leadingAnchor constraintEqualToAnchor:wrapper.leadingAnchor constant:16],
        [textStack.centerYAnchor constraintEqualToAnchor:wrapper.centerYAnchor],
        [textStack.trailingAnchor constraintLessThanOrEqualToAnchor:toggle.leadingAnchor constant:-12],
        
        [toggle.trailingAnchor constraintEqualToAnchor:wrapper.trailingAnchor constant:-16],
        [toggle.centerYAnchor constraintEqualToAnchor:wrapper.centerYAnchor],
        
        [wrapper.heightAnchor constraintGreaterThanOrEqualToConstant:60],
    ]];
    
    return wrapper;
}

- (void)closeTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)applyTapped {
    g_alwaysImpostor = impostorSwitch.on;
    g_unlockAllCosmetics = cosmeticsSwitch.on;
    g_espEnabled = espSwitch.on;
    g_autoWinEnabled = autoWinSwitch.on;
    g_noBanMode = antiBanSwitch.on;
    
    statusLabel.text = @"✅ Settings applied!";
    statusLabel.textColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0];
    
    // Update ESP visibility
    if (g_espOverlay) {
        g_espOverlay.hidden = !g_espEnabled;
        if (g_espEnabled) {
            [g_espOverlay updateESP];
        }
    }
    
    // Flash feedback
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        statusLabel.text = @"Status: Ready";
    });
    
    NSLog(@"[AmongUsCheat] Settings updated: AlwaysImpostor=%@, Cosmetics=%@, ESP=%@, AutoWin=%@, AntiBan=%@",
          g_alwaysImpostor ? @"ON" : @"OFF",
          g_unlockAllCosmetics ? @"ON" : @"OFF",
          g_espEnabled ? @"ON" : @"OFF",
          g_autoWinEnabled ? @"ON" : @"OFF",
          g_noBanMode ? @"ON" : @"OFF");
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

// ============================================================
// MARK: - Show Settings Menu
// ============================================================

static void showSettingsMenu(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) {
            window = [[UIApplication sharedApplication].windows firstObject];
        }
        
        CheatSettingsViewController *vc = [[CheatSettingsViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        [window.rootViewController presentViewController:nav animated:YES completion:nil];
    });
}

// ============================================================
// MARK: - Hook Functions - Always Impostor
// ============================================================

static BOOL (*orig_PlayerControl_get_IsImpostor)(id self, SEL sel);
static BOOL hooked_PlayerControl_get_IsImpostor(id self, SEL sel) {
    if (g_alwaysImpostor) {
        PlayerControl *localPlayer = [objc_getClass("PlayerControl") performSelector:@selector(LocalPlayer)];
        if (localPlayer && self == localPlayer) {
            return YES;
        }
        if (orig_PlayerControl_get_IsImpostor) {
            return orig_PlayerControl_get_IsImpostor(self, sel);
        }
        return NO;
    }
    return orig_PlayerControl_get_IsImpostor ? orig_PlayerControl_get_IsImpostor(self, sel) : NO;
}

static BOOL (*orig_PlayerControl_get_IsImpostor_forNetwork)(id self, SEL sel);
static BOOL hooked_PlayerControl_get_IsImpostor_forNetwork(id self, SEL sel) {
    return orig_PlayerControl_get_IsImpostor_forNetwork ? 
           orig_PlayerControl_get_IsImpostor_forNetwork(self, sel) : NO;
}

// ============================================================
// MARK: - Hook Functions - Unlock All Cosmetics
// ============================================================

@interface HatManager : NSObject
- (NSArray *)AllHats;
- (NSArray *)AllPets;
- (NSArray *)AllSkins;
- (NSArray *)AllVisors;
- (NSArray *)AllNamePlates;
+ (HatManager *)Instance;
@end

static BOOL (*orig_HasPurchased)(id self, SEL sel, id itemId);
static BOOL hooked_HasPurchased(id self, SEL sel, id itemId) {
    if (g_unlockAllCosmetics) {
        return YES;
    }
    return orig_HasPurchased ? orig_HasPurchased(self, sel, itemId) : NO;
}

static BOOL (*orig_IsAvailable)(id self, SEL sel);
static BOOL hooked_IsAvailable(id self, SEL sel) {
    if (g_unlockAllCosmetics) {
        return YES;
    }
    return orig_IsAvailable ? orig_IsAvailable(self, sel) : NO;
}

// ============================================================
// MARK: - ESP Rendering
// ============================================================

@interface ESPOverlay : UIView
@property (nonatomic, strong) NSMutableArray *playerLabels;
@property (nonatomic, strong) NSMutableDictionary *playerColors;
@end

@implementation ESPOverlay

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.playerLabels = [NSMutableArray array];
        self.playerColors = [NSMutableDictionary dictionary];
        self.hidden = !g_espEnabled;
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (window) {
            self.frame = window.bounds;
            [window addSubview:self];
            [window bringSubviewToFront:self];
        }
    }
    return self;
}

- (void)updateESP {
    if (!g_espEnabled) {
        self.hidden = YES;
        return;
    }
    self.hidden = NO;
    
    for (UILabel *label in self.playerLabels) {
        [label removeFromSuperview];
    }
    [self.playerLabels removeAllObjects];
    
    GameData *gameData = [objc_getClass("GameData") performSelector:@selector(Instance)];
    if (!gameData) return;
    
    NSArray *players = [gameData performSelector:@selector(AllPlayers)];
    if (!players) return;
    
    PlayerControl *localPlayer = [objc_getClass("PlayerControl") performSelector:@selector(LocalPlayer)];
    if (!localPlayer) return;
    
    int localId = [[localPlayer valueForKey:@"PlayerId"] intValue];
    
    for (id player in players) {
        BOOL isDead = [[player valueForKey:@"IsDead"] boolValue];
        BOOL isDisconnected = [[player valueForKey:@"IsDisconnected"] boolValue];
        if (!g_showAllPlayers && (isDead || isDisconnected)) continue;
        
        int playerId = [[player valueForKey:@"PlayerId"] intValue];
        if (playerId == localId) continue;
        
        NSString *playerName = [player valueForKey:@"name"];
        BOOL isImpostor = [[player valueForKey:@"IsImpostor"] boolValue];
        (void)[[player valueForKey:@"colorId"] intValue];
        
        id playerPhysics = [player valueForKey:@"myPhysics"];
        if (!playerPhysics) continue;
        
        CGPoint position = [[playerPhysics valueForKey:@"position"] CGPointValue];
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        CGSize screenSize = window.bounds.size;
        
        float x = position.x / 100.0f * screenSize.width + screenSize.width/2;
        float y = screenSize.height - (position.y / 100.0f * screenSize.height + screenSize.height/2);
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x - 50, y - 30, 100, 30)];
        label.text = [NSString stringWithFormat:@"%@ %@", playerName, isImpostor ? @"🔴" : @"🟢"];
        label.textColor = isImpostor ? [UIColor redColor] : [UIColor greenColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        label.layer.cornerRadius = 4;
        label.clipsToBounds = YES;
        
        [self addSubview:label];
        [self.playerLabels addObject:label];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (window) {
        self.frame = window.bounds;
    }
}

@end

static ESPOverlay *g_espOverlay = nil;

// ============================================================
// MARK: - ESP Update Timer (IMPLEMENTATION)
// ============================================================

static void updateESP(void) {
    if (g_espOverlay) {
        [g_espOverlay updateESP];
    }
}

// ============================================================
// MARK: - Hook Functions - Auto Win
// ============================================================

static void (*orig_CheckEndCriteria)(id self, SEL sel);
static void hooked_CheckEndCriteria(id self, SEL sel) {
    if (g_autoWinEnabled) {
        GameData *gameData = [objc_getClass("GameData") performSelector:@selector(Instance)];
        if (gameData) {
            NSArray *players = [gameData performSelector:@selector(AllPlayers)];
            if (players) {
                BOOL allDead = YES;
                for (id player in players) {
                    BOOL isDead = [[player valueForKey:@"IsDead"] boolValue];
                    if (!isDead) {
                        allDead = NO;
                        break;
                    }
                }
                if (allDead) {
                    return;
                }
            }
        }
        
        GameData *gd = [objc_getClass("GameData") performSelector:@selector(Instance)];
        NSArray *allPlayers = [gd performSelector:@selector(AllPlayers)];
        PlayerControl *localPlayer = [objc_getClass("PlayerControl") performSelector:@selector(LocalPlayer)];
        
        for (id player in allPlayers) {
            if (player != localPlayer) {
                BOOL isImpostor = [[player valueForKey:@"IsImpostor"] boolValue];
                if (!isImpostor) {
                    [player setValue:@YES forKey:@"IsDead"];
                    
                    SEL onMurderSel = NSSelectorFromString(@"OnMurder:isKiller:isVictim:isShapeShifted:shapeshiftTargetId:victimId:");
                    if ([localPlayer respondsToSelector:onMurderSel]) {
                        id playerId = [player valueForKey:@"PlayerId"];
                        (void)[localPlayer valueForKey:@"PlayerId"];
                        ((void (*)(id, SEL, id, BOOL, BOOL, BOOL, int, int))objc_msgSend)(
                            localPlayer, onMurderSel, playerId, YES, NO, NO, 0, [playerId intValue]
                        );
                    }
                }
            }
        }
        
        ShipStatus *shipStatus = [objc_getClass("ShipStatus") performSelector:@selector(Instance)];
        if (shipStatus) {
            [shipStatus setValue:@YES forKey:@"GameEnded"];
        }
        return;
    }
    
    if (orig_CheckEndCriteria) {
        orig_CheckEndCriteria(self, sel);
    }
}

// ============================================================
// MARK: - Anti-Ban Features (ENHANCED)
// ============================================================

static BOOL (*orig_SystemIntegrityCheck)(id, SEL);
static BOOL hooked_SystemIntegrityCheck(id self, SEL sel) {
    if (g_noBanMode) {
        return YES;
    }
    return orig_SystemIntegrityCheck ? orig_SystemIntegrityCheck(self, sel) : YES;
}

static void (*orig_ValidatePacket_enhanced)(id, SEL, id);
static void hooked_ValidatePacket_enhanced(id self, SEL sel, id packet) {
    if (g_noBanMode && packet) {
        @try {
            if ([packet respondsToSelector:@selector(setCheatReported:)]) {
                [packet setValue:@NO forKey:@"cheatReported"];
            }
            if ([packet respondsToSelector:@selector(setDetected:)]) {
                [packet setValue:@NO forKey:@"detected"];
            }
            NSArray *keys = @[@"suspicious", @"flagged", @"invalid", @"hackDetected"];
            for (NSString *key in keys) {
                NSString *setter = [NSString stringWithFormat:@"set%@:", [key capitalizedString]];
                SEL setterSel = NSSelectorFromString(setter);
                if ([packet respondsToSelector:setterSel]) {
                    [packet setValue:@0 forKey:key];
                }
            }
        } @catch (NSException *e) {
            // Silent fail
        }
        return;
    }
    if (orig_ValidatePacket_enhanced) {
        orig_ValidatePacket_enhanced(self, sel, packet);
    }
}

static BOOL (*orig_IsBanned)(id, SEL);
static BOOL hooked_IsBanned(id self, SEL sel) {
    if (g_noBanMode) {
        return NO;
    }
    return orig_IsBanned ? orig_IsBanned(self, sel) : NO;
}

static void (*orig_SendHeartbeat)(id, SEL);
static void hooked_SendHeartbeat(id self, SEL sel) {
    if (g_noBanMode) {
        if (orig_SendHeartbeat) {
            orig_SendHeartbeat(self, sel);
        }
        return;
    }
    if (orig_SendHeartbeat) {
        orig_SendHeartbeat(self, sel);
    }
}

// ============================================================
// MARK: - Additional Hook Implementations (FORWARD DECLARED)
// ============================================================

static BOOL hooked_CanMakePurchases(id self, SEL sel) {
    if (g_unlockAllCosmetics) {
        return YES;
    }
    static BOOL (*orig_CanMakePurchases)(id, SEL);
    return orig_CanMakePurchases ? orig_CanMakePurchases(self, sel) : NO;
}

static id hooked_GetProductInfo(id self, SEL sel, id productId) {
    if (g_unlockAllCosmetics) {
        return nil;
    }
    static id (*orig_GetProductInfo)(id, SEL, id);
    return orig_GetProductInfo ? orig_GetProductInfo(self, sel, productId) : nil;
}

static void hooked_OnPlayerSpawn(id self, SEL sel, id player) {
    if (g_alwaysImpostor) {
        PlayerControl *localPlayer = [objc_getClass("PlayerControl") performSelector:@selector(LocalPlayer)];
        if (player == localPlayer) {
            [player setValue:@YES forKey:@"IsImpostor"];
            
            Class roleBehaviour = objc_getClass("RoleBehaviour");
            if (roleBehaviour) {
                id impostorRole = [roleBehaviour performSelector:@selector(ImpostorRole)];
                if (impostorRole) {
                    [player setValue:impostorRole forKey:@"role"];
                }
            }
        }
    }
    
    static void (*orig_OnPlayerSpawn)(id, SEL, id);
    if (orig_OnPlayerSpawn) {
        orig_OnPlayerSpawn(self, sel, player);
    }
}

// ============================================================
// MARK: - Injection Entry Point
// ============================================================

__attribute__((constructor))
static void init_cheat(void) {
    NSLog(@"[AmongUsCheat] Injecting...");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"[AmongUsCheat] Initializing cheat features...");
        
        Class playerControl = objc_getClass("PlayerControl");
        Class gameData = objc_getClass("GameData");
        Class shipStatus = objc_getClass("ShipStatus");
        Class innerNetClient = objc_getClass("InnerNetClient");
        Class meetingHud = objc_getClass("MeetingHud");
        Class hatManager = objc_getClass("HatManager");
        
        if (!playerControl) {
            NSLog(@"[AmongUsCheat] PlayerControl class not found!");
            return;
        }
        
        // ============================================================
        // Hook PlayerControl - Always Impostor
        // ============================================================
        SEL isImpostorSel = NSSelectorFromString(@"IsImpostor");
        SEL isImpostorForNetworkSel = NSSelectorFromString(@"IsImpostorForNetwork");
        
        if (isImpostorSel) {
            Method origMethod = class_getInstanceMethod(playerControl, isImpostorSel);
            if (origMethod) {
                orig_PlayerControl_get_IsImpostor = (BOOL (*)(id, SEL))method_getImplementation(origMethod);
                class_replaceMethod(playerControl, isImpostorSel, (IMP)hooked_PlayerControl_get_IsImpostor, method_getTypeEncoding(origMethod));
                NSLog(@"[AmongUsCheat] Hooked IsImpostor");
            }
        }
        
        // ============================================================
        // Hook HatManager - Unlock All Cosmetics
        // ============================================================
        if (g_unlockAllCosmetics && hatManager) {
            SEL hasPurchasedSel = NSSelectorFromString(@"HasPurchased:");
            if (hasPurchasedSel) {
                Method origMethod = class_getInstanceMethod(hatManager, hasPurchasedSel);
                if (origMethod) {
                    orig_HasPurchased = (BOOL (*)(id, SEL, id))method_getImplementation(origMethod);
                    class_replaceMethod(hatManager, hasPurchasedSel, (IMP)hooked_HasPurchased, method_getTypeEncoding(origMethod));
                    NSLog(@"[AmongUsCheat] Hooked HasPurchased");
                }
            }
            
            SEL isAvailableSel = NSSelectorFromString(@"IsAvailable");
            if (isAvailableSel) {
                Method origMethod = class_getInstanceMethod(hatManager, isAvailableSel);
                if (origMethod) {
                    orig_IsAvailable = (BOOL (*)(id, SEL))method_getImplementation(origMethod);
                    class_replaceMethod(hatManager, isAvailableSel, (IMP)hooked_IsAvailable, method_getTypeEncoding(origMethod));
                    NSLog(@"[AmongUsCheat] Hooked IsAvailable");
                }
            }
        }
        
        // ============================================================
        // Hook ShipStatus - Auto Win
        // ============================================================
        if (g_autoWinEnabled && shipStatus) {
            SEL checkEndSel = NSSelectorFromString(@"CheckEndCriteria");
            if (checkEndSel) {
                Method origMethod = class_getInstanceMethod(shipStatus, checkEndSel);
                if (origMethod) {
                    orig_CheckEndCriteria = (void (*)(id, SEL))method_getImplementation(origMethod);
                    class_replaceMethod(shipStatus, checkEndSel, (IMP)hooked_CheckEndCriteria, method_getTypeEncoding(origMethod));
                    NSLog(@"[AmongUsCheat] Hooked CheckEndCriteria");
                }
            }
        }
        
        // ============================================================
        // Hook Anti-Cheat - Enhanced Anti-Ban
        // ============================================================
        if (g_noBanMode) {
            NSArray *antiCheatClasses = @[
                @"AntiCheatManager",
                @"SecurityManager",
                @"IntegrityChecker",
                @"CheatDetection",
                @"ServerValidator",
                @"BanManager"
            ];
            
            for (NSString *className in antiCheatClasses) {
                Class cls = objc_getClass([className UTF8String]);
                if (!cls) continue;
                
                SEL integritySel = NSSelectorFromString(@"VerifyIntegrity");
                if (integritySel) {
                    Method m = class_getInstanceMethod(cls, integritySel);
                    if (m) {
                        orig_SystemIntegrityCheck = (BOOL (*)(id, SEL))method_getImplementation(m);
                        class_replaceMethod(cls, integritySel, (IMP)hooked_SystemIntegrityCheck, method_getTypeEncoding(m));
                        NSLog(@"[AmongUsCheat] Hooked %@.VerifyIntegrity", className);
                    }
                }
                
                SEL banSel = NSSelectorFromString(@"IsDeviceBanned");
                if (banSel) {
                    Method m = class_getInstanceMethod(cls, banSel);
                    if (m) {
                        orig_IsBanned = (BOOL (*)(id, SEL))method_getImplementation(m);
                        class_replaceMethod(cls, banSel, (IMP)hooked_IsBanned, method_getTypeEncoding(m));
                        NSLog(@"[AmongUsCheat] Hooked %@.IsDeviceBanned", className);
                    }
                }
            }
            
            if (innerNetClient) {
                SEL validateSel = NSSelectorFromString(@"ValidatePacket:");
                if (validateSel) {
                    Method origMethod = class_getInstanceMethod(innerNetClient, validateSel);
                    if (origMethod) {
                        orig_ValidatePacket_enhanced = (void (*)(id, SEL, id))method_getImplementation(origMethod);
                        class_replaceMethod(innerNetClient, validateSel, (IMP)hooked_ValidatePacket_enhanced, method_getTypeEncoding(origMethod));
                        NSLog(@"[AmongUsCheat] Hooked ValidatePacket (enhanced)");
                    }
                }
                
                SEL heartbeatSel = NSSelectorFromString(@"SendHeartbeat");
                if (heartbeatSel) {
                    Method m = class_getInstanceMethod(innerNetClient, heartbeatSel);
                    if (m) {
                        orig_SendHeartbeat = (void (*)(id, SEL))method_getImplementation(m);
                        class_replaceMethod(innerNetClient, heartbeatSel, (IMP)hooked_SendHeartbeat, method_getTypeEncoding(m));
                        NSLog(@"[AmongUsCheat] Hooked SendHeartbeat");
                    }
                }
            }
        }
        
        // ============================================================
        // Setup ESP
        // ============================================================
        if (g_espEnabled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                g_espOverlay = [[ESPOverlay alloc] init];
                
                // FIXED: Use block-based timer, updateESP is now declared
                [NSTimer scheduledTimerWithTimeInterval:0.1
                                                repeats:YES
                                                  block:^(NSTimer *timer) {
                    updateESP();
                }];
                
                NSLog(@"[AmongUsCheat] ESP initialized");
            });
        }
        
        // ============================================================
        // Hook IAP Manager - Additional Anti-Ban/Unlock
        // ============================================================
        Class iapManager = objc_getClass("IAPManager");
        if (iapManager) {
            SEL canMakePurchasesSel = NSSelectorFromString(@"CanMakePurchases");
            if (canMakePurchasesSel) {
                Method origMethod = class_getInstanceMethod(iapManager, canMakePurchasesSel);
                if (origMethod) {
                    static BOOL (*orig_CanMakePurchases)(id, SEL);
                    orig_CanMakePurchases = (BOOL (*)(id, SEL))method_getImplementation(origMethod);
                    class_replaceMethod(iapManager, canMakePurchasesSel, (IMP)hooked_CanMakePurchases, method_getTypeEncoding(origMethod));
                    NSLog(@"[AmongUsCheat] Hooked CanMakePurchases");
                }
            }
        }
        
        Class storeManager = objc_getClass("StoreManager");
        if (storeManager) {
            SEL getProductInfoSel = NSSelectorFromString(@"GetProductInfo:");
            if (getProductInfoSel) {
                Method origMethod = class_getInstanceMethod(storeManager, getProductInfoSel);
                if (origMethod) {
                    static id (*orig_GetProductInfo)(id, SEL, id);
                    orig_GetProductInfo = (id (*)(id, SEL, id))method_getImplementation(origMethod);
                    class_replaceMethod(storeManager, getProductInfoSel, (IMP)hooked_GetProductInfo, method_getTypeEncoding(origMethod));
                    NSLog(@"[AmongUsCheat] Hooked GetProductInfo");
                }
            }
        }
        
        // Hook player spawn
        if (playerControl) {
            SEL onSpawnSel = NSSelectorFromString(@"OnSpawn");
            if (onSpawnSel) {
                Method origMethod = class_getInstanceMethod(playerControl, onSpawnSel);
                if (origMethod) {
                    static void (*orig_OnPlayerSpawn)(id, SEL, id);
                    orig_OnPlayerSpawn = (void (*)(id, SEL, id))method_getImplementation(origMethod);
                    class_replaceMethod(playerControl, onSpawnSel, (IMP)hooked_OnPlayerSpawn, method_getTypeEncoding(origMethod));
                    NSLog(@"[AmongUsCheat] Hooked OnSpawn");
                }
            }
        }
        
        // ============================================================
        // Add gesture to show settings menu (triple tap on screen)
        // ============================================================
        dispatch_async(dispatch_get_main_queue(), ^{
            UIWindow *window = [UIApplication sharedApplication].keyWindow;
            if (!window) {
                window = [[UIApplication sharedApplication].windows firstObject];
            }
            
            // Add a gesture recognizer to show the settings menu
            UITapGestureRecognizer *tripleTap = [[UITapGestureRecognizer alloc] initWithTarget:nil action:nil];
            tripleTap.numberOfTapsRequired = 3;
            [tripleTap addTarget:self action:@selector(showSettingsMenu)];
            [window addGestureRecognizer:tripleTap];
            
            NSLog(@"[AmongUsCheat] Triple-tap gesture added to show settings menu");
        });
        
        NSLog(@"[AmongUsCheat] Injection complete!");
        NSLog(@"[AmongUsCheat] Features: AlwaysImpostor=%@, Cosmetics=%@, ESP=%@, AutoWin=%@, AntiBan=%@",
              g_alwaysImpostor ? @"ON" : @"OFF",
              g_unlockAllCosmetics ? @"ON" : @"OFF",
              g_espEnabled ? @"ON" : @"OFF",
              g_autoWinEnabled ? @"ON" : @"OFF",
              g_noBanMode ? @"ON" : @"OFF");
    });
}

// ============================================================
// MARK: - Command Handling (for debugging)
// ============================================================

extern "C" void ToggleImpostor() {
    g_alwaysImpostor = !g_alwaysImpostor;
    NSLog(@"[AmongUsCheat] AlwaysImpostor: %@", g_alwaysImpostor ? @"ON" : @"OFF");
}

extern "C" void ToggleESP() {
    g_espEnabled = !g_espEnabled;
    if (g_espOverlay) {
        g_espOverlay.hidden = !g_espEnabled;
    }
    NSLog(@"[AmongUsCheat] ESP: %@", g_espEnabled ? @"ON" : @"OFF");
}

extern "C" void ToggleAutoWin() {
    g_autoWinEnabled = !g_autoWinEnabled;
    NSLog(@"[AmongUsCheat] AutoWin: %@", g_autoWinEnabled ? @"ON" : @"OFF");
}

extern "C" void ToggleAntiBan() {
    g_noBanMode = !g_noBanMode;
    NSLog(@"[AmongUsCheat] AntiBan: %@", g_noBanMode ? @"ON" : @"OFF");
}

// ============================================================
// MARK: - Memory Analysis Helper
// ============================================================

extern "C" void AnalyzeMemory() {
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    NSMutableArray *gameClasses = [NSMutableArray array];
    for (int i = 0; i < numClasses; i++) {
        NSString *className = NSStringFromClass(classes[i]);
        if ([className hasPrefix:@"AmongUs"] || 
            [className hasPrefix:@"Player"] ||
            [className hasPrefix:@"Game"]) {
            [gameClasses addObject:className];
        }
    }
    free(classes);
    
    NSLog(@"[AmongUsCheat] Found game classes: %@", gameClasses);
}
