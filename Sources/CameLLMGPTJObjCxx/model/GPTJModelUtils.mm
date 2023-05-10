//
//  GPTJModelUtils.m
//  
//
//  Created by Alex Rozanski on 10/05/2023.
//

#import "GPTJModelUtils.h"

#import "gptj.hh"

@implementation _GPTJModelUtils

+ (BOOL)validateModelAtURL:(NSURL *)fileURL outError:(NSError **)outError
{
  if (fileURL.path.length == 0) {
    return NO;
  }

  LLModel *gptJ = new GPTJ;
  const std::string modelPath([fileURL.path cStringUsingEncoding:NSUTF8StringEncoding]);
  bool isValid = gptJ->verifyMagic(modelPath, outError);
  delete gptJ;
  return !!isValid;
}

@end
