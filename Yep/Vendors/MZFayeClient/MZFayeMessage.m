//
//  MZFayeMessage.m
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

#import "MZFayeMessage.h"

@implementation MZFayeMessage

- (instancetype)initFromDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        self.Id = dictionary[@"id"];
        self.channel = dictionary[@"channel"];
        self.clientId = dictionary[@"clientId"];
        self.successful = @([dictionary[@"successful"] boolValue]);
        self.authSuccessful = @([dictionary[@"authSuccessful"] boolValue]);
        self.version = dictionary[@"version"];
        self.minimumVersion = dictionary[@"minimumVersion"];
        self.supportedConnectionTypes = dictionary[@"supportedConnectionTypes"];
        self.advice = dictionary[@"advice"];
        self.error = dictionary[@"error"];
        self.subscription = dictionary[@"subscription"];
        self.timestamp = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"timestamp"] timeInterval]];
        self.data = dictionary[@"data"];
        self.ext = dictionary[@"ext"];
    }
    return self;
}

+ (instancetype)messageFromDictionary:(NSDictionary *)dictionary
{
    return [[[self class] alloc] initFromDictionary:dictionary];
}

@end
