//
//  MZFayeMessage.h
//  MZFayeClient
//
//  Created by Michał Zaborowski on 12.12.2013.
//  Copyright (c) 2013 Michał Zaborowski. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <Foundation/Foundation.h>

@interface MZFayeMessage : NSObject

@property (nonatomic, strong) NSString *Id;
@property (nonatomic, strong) NSString *channel;
@property (nonatomic, strong) NSString *clientId;
@property (nonatomic, strong) NSNumber *successful;
@property (nonatomic, strong) NSNumber *authSuccessful;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *minimumVersion;
@property (nonatomic, strong) NSArray *supportedConnectionTypes;
@property (nonatomic, strong) NSDictionary *advice;
@property (nonatomic, strong) NSString *error;
@property (nonatomic, strong) NSString *subscription;
@property (nonatomic, strong) NSDate *timestamp;
@property (nonatomic, strong) NSDictionary *data;
@property (nonatomic, strong) NSDictionary *ext;

+ (instancetype)messageFromDictionary:(NSDictionary *)dictionary;

@end
