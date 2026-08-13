#import <Cocoa/Cocoa.h>
#import <ServiceManagement/ServiceManagement.h>

@interface MySpeedAppDelegate : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) NSMenuItem *statusMenuItem;
@property(nonatomic, strong) NSMenuItem *loginMenuItem;
@property(nonatomic, strong) NSTask *backend;
@property(nonatomic, strong) NSFileHandle *logHandle;
@property(nonatomic, strong) NSTimer *healthTimer;
@property(nonatomic, strong) NSURL *supportDirectory;
@property(nonatomic) NSInteger healthAttempts;
@property(nonatomic) BOOL isQuitting;
@property(nonatomic) BOOL ownsBackend;
@end

@implementation MySpeedAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSURL *applicationSupport = [[[NSFileManager defaultManager]
        URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] firstObject];
    self.supportDirectory = [applicationSupport URLByAppendingPathComponent:@"MySpeed" isDirectory:YES];
    [self configureMenu];

    NSError *error = nil;
    if (![self prepareRuntime:&error]) {
        [self setStatus:@"启动失败"];
        [self showError:[NSString stringWithFormat:@"MySpeed 无法准备运行目录：%@", error.localizedDescription]];
        return;
    }
    [self probeExistingServer];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    self.isQuitting = YES;
    [self.healthTimer invalidate];
    if (self.ownsBackend && self.backend.running) {
        [self.backend terminate];
        [self.backend waitUntilExit];
    }
    [self.logHandle closeFile];
}

- (void)configureMenu {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.image = [NSImage imageWithSystemSymbolName:@"gauge.with.dots.needle.50percent"
                                            accessibilityDescription:@"MySpeed"];
    self.statusItem.button.toolTip = @"MySpeed CN";

    NSMenu *menu = [[NSMenu alloc] init];
    self.statusMenuItem = [[NSMenuItem alloc] initWithTitle:@"正在启动…" action:nil keyEquivalent:@""];
    self.statusMenuItem.enabled = NO;
    [menu addItem:self.statusMenuItem];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:[self menuItem:@"打开控制面板" action:@selector(openDashboard:) key:@"o"]];
    [menu addItem:[self menuItem:@"重新启动服务" action:@selector(restartBackend:) key:@"r"]];
    [menu addItem:[self menuItem:@"打开数据目录" action:@selector(openDataDirectory:) key:@""]];
    [menu addItem:[self menuItem:@"查看运行日志" action:@selector(openLog:) key:@""]];
    [menu addItem:[NSMenuItem separatorItem]];

    self.loginMenuItem = [self menuItem:@"登录时自动启动" action:@selector(toggleLoginItem:) key:@""];
    self.loginMenuItem.state = SMAppService.mainAppService.status == SMAppServiceStatusEnabled
        ? NSControlStateValueOn : NSControlStateValueOff;
    [menu addItem:self.loginMenuItem];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:[self menuItem:@"退出 MySpeed" action:@selector(quit:) key:@"q"]];
    self.statusItem.menu = menu;
}

- (NSMenuItem *)menuItem:(NSString *)title action:(SEL)action key:(NSString *)key {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:key];
    item.target = self;
    return item;
}

- (BOOL)prepareRuntime:(NSError **)error {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray<NSURL *> *directories = @[
        self.supportDirectory,
        [self.supportDirectory URLByAppendingPathComponent:@"bin" isDirectory:YES],
        [self.supportDirectory URLByAppendingPathComponent:@"data/logs" isDirectory:YES],
        [self.supportDirectory URLByAppendingPathComponent:@"data/servers" isDirectory:YES],
        [self.supportDirectory URLByAppendingPathComponent:@"data/certs" isDirectory:YES]
    ];
    for (NSURL *directory in directories) {
        if (![manager createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:error]) return NO;
    }

    NSURL *bundledBin = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"bin" isDirectory:YES];
    NSURL *destinationBin = [self.supportDirectory URLByAppendingPathComponent:@"bin" isDirectory:YES];
    NSArray<NSURL *> *providers = [manager contentsOfDirectoryAtURL:bundledBin
                                         includingPropertiesForKeys:nil options:0 error:error];
    if (!providers) return NO;

    for (NSURL *source in providers) {
        NSURL *destination = [destinationBin URLByAppendingPathComponent:source.lastPathComponent];
        if ([manager fileExistsAtPath:destination.path] && ![manager removeItemAtURL:destination error:error]) return NO;
        if (![manager copyItemAtURL:source toURL:destination error:error]) return NO;
        if (![manager setAttributes:@{NSFilePosixPermissions: @0755} ofItemAtPath:destination.path error:error]) return NO;
    }

    NSURL *logURL = [self.supportDirectory URLByAppendingPathComponent:@"data/logs/macos-app.log"];
    if (![manager fileExistsAtPath:logURL.path]) [manager createFileAtPath:logURL.path contents:nil attributes:nil];
    self.logHandle = [NSFileHandle fileHandleForWritingAtPath:logURL.path];
    [self.logHandle seekToEndOfFile];
    return self.logHandle != nil;
}

- (void)probeExistingServer {
    NSURL *dashboard = [NSURL URLWithString:@"http://127.0.0.1:5216"];
    __weak typeof(self) weakSelf = self;
    [[[NSURLSession sharedSession] dataTaskWithURL:dashboard
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(self) self = weakSelf;
                if (!self) return;
                if ([(NSHTTPURLResponse *)response statusCode] == 200) {
                    self.ownsBackend = NO;
                    [self setStatus:@"服务运行中"];
                } else {
                    [self startBackendAndOpen:YES];
                }
            });
        }] resume];
}

- (void)startBackendAndOpen:(BOOL)openWhenReady {
    if (self.backend.running) return;
    NSURL *backendURL = [[[[NSBundle mainBundle] executableURL] URLByDeletingLastPathComponent]
                         URLByAppendingPathComponent:@"MySpeedBackend"];
    if (![[NSFileManager defaultManager] isExecutableFileAtPath:backendURL.path]) {
        [self setStatus:@"后端缺失"];
        [self showError:@"应用包内缺少 MySpeedBackend。请重新安装应用。"];
        return;
    }

    NSTask *task = [[NSTask alloc] init];
    task.executableURL = backendURL;
    task.currentDirectoryURL = self.supportDirectory;
    NSMutableDictionary *environment = [[[NSProcessInfo processInfo] environment] mutableCopy];
    if (!environment[@"SERVER_PORT"]) environment[@"SERVER_PORT"] = @"5216";
    if (!environment[@"MYSPEED_DEFAULT_PROVIDER"]) environment[@"MYSPEED_DEFAULT_PROVIDER"] = @"libre";
    if (!environment[@"MYSPEED_DEFAULT_LIBRE_ID"]) environment[@"MYSPEED_DEFAULT_LIBRE_ID"] = @"cn-edu-nju";
    if (!environment[@"MYSPEED_SKIP_OOKLA_DOWNLOAD"]) environment[@"MYSPEED_SKIP_OOKLA_DOWNLOAD"] = @"true";
    task.environment = environment;
    task.standardOutput = self.logHandle;
    task.standardError = self.logHandle;

    __weak typeof(self) weakSelf = self;
    task.terminationHandler = ^(NSTask *finishedTask) {
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) self = weakSelf;
            if (!self) return;
            self.backend = nil;
            self.ownsBackend = NO;
            if (!self.isQuitting) {
                [self setStatus:[NSString stringWithFormat:@"服务已停止（%d）", finishedTask.terminationStatus]];
            }
        });
    };

    NSError *error = nil;
    if ([task launchAndReturnError:&error]) {
        self.backend = task;
        self.ownsBackend = YES;
        [self setStatus:@"正在启动服务…"];
        [self beginHealthChecksAndOpen:openWhenReady];
    } else {
        [self setStatus:@"启动失败"];
        [self showError:[NSString stringWithFormat:@"MySpeed 后端启动失败：%@", error.localizedDescription]];
    }
}

- (void)beginHealthChecksAndOpen:(BOOL)openWhenReady {
    [self.healthTimer invalidate];
    self.healthAttempts = 0;
    __weak typeof(self) weakSelf = self;
    self.healthTimer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer *timer) {
        typeof(self) self = weakSelf;
        if (!self) { [timer invalidate]; return; }
        self.healthAttempts += 1;
        NSURL *dashboard = [NSURL URLWithString:@"http://127.0.0.1:5216"];
        [[[NSURLSession sharedSession] dataTaskWithURL:dashboard
            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([(NSHTTPURLResponse *)response statusCode] == 200) {
                        [timer invalidate];
                        [self setStatus:@"服务运行中"];
                        if (openWhenReady) [self openDashboard:nil];
                    } else if (self.healthAttempts >= 30) {
                        [timer invalidate];
                        [self setStatus:@"服务没有响应"];
                    }
                });
            }] resume];
    }];
}

- (void)setStatus:(NSString *)text {
    self.statusMenuItem.title = text;
    self.statusItem.button.toolTip = [NSString stringWithFormat:@"MySpeed CN · %@", text];
}

- (void)showError:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleCritical;
    alert.messageText = @"MySpeed CN";
    alert.informativeText = message;
    [alert runModal];
}

- (void)openDashboard:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://127.0.0.1:5216"]];
}

- (void)openDataDirectory:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:self.supportDirectory];
}

- (void)openLog:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[self.supportDirectory URLByAppendingPathComponent:@"data/logs/macos-app.log"]];
}

- (void)restartBackend:(id)sender {
    [self.healthTimer invalidate];
    if (self.ownsBackend && self.backend.running) {
        self.isQuitting = YES;
        [self.backend terminate];
        [self.backend waitUntilExit];
        self.isQuitting = NO;
    }
    self.backend = nil;
    self.ownsBackend = NO;
    [self startBackendAndOpen:NO];
}

- (void)toggleLoginItem:(id)sender {
    NSError *error = nil;
    SMAppService *service = SMAppService.mainAppService;
    BOOL success = service.status == SMAppServiceStatusEnabled
        ? [service unregisterAndReturnError:&error]
        : [service registerAndReturnError:&error];
    if (!success) {
        [self showError:[NSString stringWithFormat:@"无法修改登录项：%@", error.localizedDescription]];
    }
    self.loginMenuItem.state = service.status == SMAppServiceStatusEnabled
        ? NSControlStateValueOn : NSControlStateValueOff;
}

- (void)quit:(id)sender {
    [[NSApplication sharedApplication] terminate:nil];
}

@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *application = [NSApplication sharedApplication];
        MySpeedAppDelegate *delegate = [[MySpeedAppDelegate alloc] init];
        application.delegate = delegate;
        [application setActivationPolicy:NSApplicationActivationPolicyAccessory];
        [application run];
    }
    return 0;
}
