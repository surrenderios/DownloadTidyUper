
//
//  AppDelegate.m
//  DownloadTidyUper
//
//  Created by surrender on 14-1-2.
//
//

#import "AppDelegate.h"
#import "SFBPopover.h"

@interface AppDelegate ()
{
@private
    SFBPopover * _popover;
}

@end

@implementation AppDelegate

#define kDMG          @"DMG"
#define kZIP          @"ZIP"
#define kMOVIE        @"Movies"
#define kMP3          @"Mp3"
#define kPIC          @"Pictures"
#define kDocs         @"Document"
#define kApplication  @"Applications"

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}


- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    [self.window makeKeyAndOrderFront:nil];
    return YES;
}

- (void)awakeFromNib
{
    _dic = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"typeDic" ofType:@"plist"]];
    [_progressIndocator setMinValue:0.0];
    [_progressIndocator setMaxValue:100.0];
    
    //localized
    [_nameLabel setStringValue:NSLocalizedString(@"name_label", nil)];
    [_startButton setTitle:NSLocalizedString(@"start_button", nil)];
    [_undoButton setTitle:NSLocalizedString(@"undo_button", nil)];
    [_textInfo setStringValue:NSLocalizedString(@"text_info", nil)];
    
    
    //set _popOver
    _popover = [[SFBPopover alloc] initWithContentView:_customView];
    [_popover setBackgroundColor:[NSColor controlColor]];
    [_popover setDrawsArrow:YES];
    [_popover setPosition:SFBPopoverPositionBottom];
    [_popover setMovable:NO];
}


- (IBAction)start:(id)sender
{
    if (_isTidy) {
        return;
    }
    
    if (_finished) {
        NSAlert *alert = [self cancelAlert];
        [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
    }
    
    BOOL finished = [self tidyDownloads];
    
    //开始整理
    if (finished && !_isTidy) {
        sleep(1);
  
        NSAlert *alert = [self openDownloadAlert];
        [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(openaAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    }
}




- (IBAction)undo:(id)sender
{
    if (_isTidy) {
        return;
    }
    if (_finished) {
        NSAlert *alert = [self WarmingAlert];
        [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    }
}

- (IBAction)help:(id)sender
{
    if ([_popover isVisible]) {
        [_popover closePopover:sender];
    }else{
        NSPoint where = [_helpButton frame].origin;
		where.x += [_helpButton frame].size.width / 2;
		where.y += [_helpButton frame].size.height / 2;
        
		[_popover displayPopoverInWindow:[_helpButton window] atPoint:where];
    }
}

#pragma delegate
- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode == NSAlertDefaultReturn) {
        return;
    }else{
        //取消之前的整理
        [self cancelTydiUp];
    }
}

- (void) openaAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode == NSAlertDefaultReturn)  [[NSWorkspace sharedWorkspace]openFile:[[self DownloadPath] path]];
}
/*********************************分割线*******************************/


- (NSURL *)DownloadPath
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDownloadsDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSArray *)tidyUpFolderPath
{
    NSString *dPath = [[self DownloadPath] path];
    NSString *dmg = [dPath stringByAppendingPathComponent:kDMG];
    NSString *zip = [dPath stringByAppendingPathComponent:kZIP];
    NSString *movie = [dPath stringByAppendingPathComponent:kMOVIE];
    NSString *mp3 = [dPath stringByAppendingPathComponent:kMP3];
    NSString *pic = [dPath stringByAppendingPathComponent:kPIC];
    NSString *docs = [dPath stringByAppendingPathComponent:kDocs];
    NSString *apps = [dPath stringByAppendingPathComponent:kApplication];
    return @[dmg,zip,movie,mp3,pic,docs,apps];
}

- (BOOL)tidyDownloads
{
     _isTidy = YES;
    
    [_progressIndocator setDoubleValue:0.0];
    [_progressIndocator incrementBy:20.0];

    NSFileManager *fm = [NSFileManager defaultManager];
    
    //get download path
    NSString *DownloadPath = [[self DownloadPath] path];
    
    //first of all,get all the files in Downloads
    NSArray *DownloadFiles = [fm contentsOfDirectoryAtPath:DownloadPath error:nil];
    
    //if  few files,promote user do not have to tidy up
    if ([DownloadFiles count] < 10) {
        NSAlert *alert = [self doNotNeedAlert];
        [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
    }
    
    NSArray *folderNames = [self tidyUpFolderPath];
    for (NSString *path in folderNames) {
        if ([fm fileExistsAtPath:path]) {
              continue;
        }
        //else create a folder
        BOOL createBool  =  [fm createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
        if (!createBool) NSLog(@"error create folder");
    }
    
    NSString *dmgPath = [folderNames objectAtIndex:0];
    NSString *zipPath = [folderNames objectAtIndex:1];
    NSString *moviePath = [folderNames objectAtIndex:2];
    NSString *mp3Path = [folderNames objectAtIndex:3];
    NSString *picPath = [folderNames objectAtIndex:3];
    NSString *docPath = [folderNames objectAtIndex:5];
    NSString *appPath = [folderNames objectAtIndex:6];
    
    NSArray *dmgArray = [_dic objectForKey:kDMG];
    NSArray *zipArray = [_dic objectForKey:kZIP];
    NSArray *movieArray = [_dic objectForKey:kMOVIE];
    NSArray *mp3Array = [_dic objectForKey:kMP3];
    NSArray *picArray = [_dic objectForKey:kPIC];
    NSArray *docArray = [_dic objectForKey:kDocs];
    NSArray *appArray = [_dic objectForKey:kApplication];
    

    //   __block dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    dispatch_queue_t queue = dispatch_queue_create("move path", NULL);
    
    dispatch_sync(queue, ^(void){
        for (NSString *path in DownloadFiles) {
            
            NSString *fullPath = [DownloadPath stringByAppendingPathComponent:path];
            NSString *extension = [path pathExtension];
            if (![fm fileExistsAtPath:fullPath]) {
                NSLog(@"file not exist");
                continue;
            }
            
            if ([dmgArray containsObject:extension]) {
                if (![fm moveItemAtPath:fullPath toPath:[dmgPath stringByAppendingPathComponent:path] error:nil]) NSLog(@"move %@ failed",path);
            }
            else if ([zipArray containsObject:extension]){
                if (![fm moveItemAtPath:fullPath toPath:[zipPath stringByAppendingPathComponent:path] error:nil]) NSLog(@"move %@ failed",path);
            }
            else if ([movieArray containsObject:extension]){
                if (![fm moveItemAtPath:fullPath toPath:[moviePath stringByAppendingPathComponent:path] error:nil]) NSLog(@"move %@ failed",path);
                
            }
            else if ([mp3Array containsObject:extension]){
                if (![fm moveItemAtPath:fullPath toPath:[mp3Path stringByAppendingPathComponent:path] error:nil]) NSLog(@"move %@ failed",path);
            }
            else if ([picArray containsObject:extension]){
                if (![fm moveItemAtPath:fullPath toPath:[picPath stringByAppendingPathComponent:path] error:nil]) NSLog(@"move %@ failed",path);
            }
            else if ([docArray containsObject:extension]){
                if (![fm moveItemAtPath:fullPath toPath:[docPath stringByAppendingPathComponent:path] error:nil]) NSLog(@"move %@ failed",path);
            }
            else if ([appArray containsObject:extension]){
                if (![fm moveItemAtPath:fullPath toPath:[appPath stringByAppendingPathComponent:path] error:nil]) NSLog(@"move %@ failed",path);
            }
        }
        
        //    dispatch_semaphore_signal(sem);
    });
    //  dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    //  dispatch_release(sem);
    //   dispatch_release(queue);

    _isTidy = NO;
    _finished = YES;
    [_progressIndocator setDoubleValue:100.0];
    
     return YES;
}

- (void)cancelTydiUp
{
    [_progressIndocator setDoubleValue:0.0];
    [_progressIndocator incrementBy:20.0];
    _isTidy = YES;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *DownloadPath = [[self DownloadPath] path];
    NSArray *folderNames = [self tidyUpFolderPath];
    for (NSString *path in folderNames) {
        if (![fm fileExistsAtPath:path]) continue;

        NSArray *content = [fm contentsOfDirectoryAtPath:path error:nil];
        for (NSString *cPath in content) {
            NSString *fullPath = [path stringByAppendingPathComponent:cPath];
            if (![fm moveItemAtPath:fullPath toPath:[DownloadPath stringByAppendingPathComponent:cPath]error:nil]) {
                NSLog(@"move %@ failed",fullPath);
            }
        }
    }
    
    _finished = NO;
    _isTidy = NO;
    [_progressIndocator setDoubleValue:100.0];
}




- (NSAlert *)WarmingAlert
{
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"attention", nil) defaultButton:NSLocalizedString(@"no",nil) alternateButton:NSLocalizedString(@"yes", nil) otherButton:nil informativeTextWithFormat:NSLocalizedString(@"WarmingAlert_message", nil)];
    return alert;
}

- (NSAlert *)cancelAlert
{
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"attention", nil) defaultButton:NSLocalizedString(@"yes", nil) alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"cancelAlert_message", nil)];
    return alert;
}

- (NSAlert *)doNotNeedAlert
{
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"attention", nil) defaultButton:NSLocalizedString(@"yes", nil) alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"doNotNeedAlert", nil)];
    return alert;
}

- (NSAlert *)openDownloadAlert
{
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"congratulations", nil) defaultButton:NSLocalizedString(@"yes", nil)alternateButton:NSLocalizedString(@"no",nil) otherButton:Nil informativeTextWithFormat:NSLocalizedString(@"openDownloadAlert", nil)];
    return alert;
}


@end
