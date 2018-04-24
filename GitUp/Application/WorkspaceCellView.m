//
//  WorkspaceCellView.m
//  Application
//
//  Created by Wu Tian on 2018/4/24.
//

#import "WorkspaceCellView.h"

@implementation WorkspaceCellView

- (void)awakeFromNib {
  // We want it to appear "inline"
  [[self.badgeButton cell] setBezelStyle:NSInlineBezelStyle];
}

// The standard rowSizeStyle does some specific layout for us. To customize layout for our button, we first call super and then modify things
- (void)viewWillDraw {
  [super viewWillDraw];
  
  CGFloat paddingLeft = 10;
  CGFloat paddingRight = 15;

  if (![self.badgeButton isHidden]) {
    [self.badgeButton sizeToFit];
    
    NSRect textFrame = self.textField.frame;
    NSRect buttonFrame = self.badgeButton.frame;
    buttonFrame.origin.x = NSWidth(self.frame) - NSWidth(buttonFrame) - paddingRight;
    self.badgeButton.frame = buttonFrame;
    textFrame.size.width = NSMinX(buttonFrame) - NSMinX(textFrame) - paddingLeft;
    textFrame.origin.x = paddingLeft;
    self.textField.frame = textFrame;
  } else {
    NSRect textFrame = self.textField.frame;
    textFrame.size.width = NSWidth(self.frame) - paddingRight - paddingLeft;
    textFrame.origin.x = paddingLeft;
    self.textField.frame = textFrame;
  }
}

@end
