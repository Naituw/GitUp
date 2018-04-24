//
//  WorkspaceCellView.h
//  Application
//
//  Created by Wu Tian on 2018/4/24.
//

#import <Cocoa/Cocoa.h>

@interface WorkspaceCellView : NSTableRowView

@property (nonatomic, weak) IBOutlet NSTextField * textField;
@property (nonatomic, weak) IBOutlet NSButton * badgeButton;

@end
