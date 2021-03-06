#import "CordovaPluginStockfish.h"
#import "CordovaPluginStockfishios.h"
#import <Cordova/CDVPlugin.h>

@implementation CordovaPluginStockfish

NSString *outputCallback = nil;
NSNumber *isInit = @FALSE;

- (void)init:(CDVInvokedUrlCommand*)command
{
  [self.commandDelegate runInBackground:^{
    /* NSLog(@"DEBUG>>> INIT EXECUTED"); */

    if(![isInit boolValue]) {
      stockfishios::init((__bridge void*)self);
      isInit = @TRUE;
    }
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }];
}

- (void)cmd:(CDVInvokedUrlCommand*)command
{
  [self.commandDelegate runInBackground:^{
    /* NSLog(@"DEBUG>>> %@", [command.arguments objectAtIndex:0]); */
    if([isInit boolValue]) {
      NSString* cmd = [command.arguments objectAtIndex:0];
      CDVPluginResult* pluginResult = nil;
      if (cmd != nil) {
        stockfishios::cmd(std::string([cmd UTF8String]));
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
      } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Missing cmd arg"];
      }
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    else {
      NSString *error = @"Please exec init before doing anything";
      CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
  }];
}

- (void)output:(CDVInvokedUrlCommand*)command
{
  outputCallback = command.callbackId;
}

- (void)exit:(CDVInvokedUrlCommand*)command
{
  if([isInit boolValue]) {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    stockfishios::cmd("quit");
    stockfishios::exit();
    isInit = @FALSE;
    /* NSLog(@"DEBUG>>> EXIT EXECUTED"); */
    outputCallback = nil;
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  } else {
    NSString *error = @"Stockfish isn't currently running!";
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }
}

- (void)sendOutput:(NSString *) output
{
  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:output];
  [pluginResult setKeepCallbackAsBool:YES];
  if (outputCallback != nil) {
    [self.commandDelegate sendPluginResult:pluginResult callbackId:outputCallback];
  }
}

- (void)onAppTerminate
{
  [self.commandDelegate runInBackground:^{
    if([isInit boolValue]) {
      stockfishios::cmd("quit");
      stockfishios::exit();
      outputCallback = nil;
      isInit = @FALSE;
    }
  }];
}

void StockfishSendOutput (void *stockfish, const char *output)
{
  [(__bridge id) stockfish sendOutput:[NSString stringWithUTF8String:output]];
}

@end
