//
//  MZFayeClient.m
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

#import "MZFayeClient.h"
#import "MZFayeMessage.h"
#import "MF_Base64Additions.h"

NSString *const MZFayeClientBayeuxChannelHandshake = @"/meta/handshake";
NSString *const MZFayeClientBayeuxChannelConnect = @"/meta/connect";
NSString *const MZFayeClientBayeuxChannelDisconnect = @"/meta/disconnect";
NSString *const MZFayeClientBayeuxChannelSubscribe = @"/meta/subscribe";
NSString *const MZFayeClientBayeuxChannelUnsubscribe = @"/meta/unsubscribe";

NSString *const MZFayeClientBayeuxMessageChannelKey = @"channel";
NSString *const MZFayeClientBayeuxMessageClientIdKey = @"clientId";
NSString *const MZFayeClientBayeuxMessageIdKey = @"id";
NSString *const MZFayeClientBayeuxMessageDataKey = @"data";
NSString *const MZFayeClientBayeuxMessageSubscriptionKey = @"subscription";
NSString *const MZFayeClientBayeuxMessageExtensionKey = @"ext";
NSString *const MZFayeClientBayeuxMessageVersionKey = @"version";
NSString *const MZFayeClientBayeuxMessageMinimuVersionKey = @"minimumVersion";
NSString *const MZFayeClientBayeuxMessageSupportedConnectionTypesKey = @"supportedConnectionTypes";
NSString *const MZFayeClientBayeuxMessageConnectionTypeKey = @"connectionType";

NSString *const MZFayeClientBayeuxVersion = @"1.0";
NSString *const MZFayeClientBayeuxMinimumVersion = @"1.0beta";

NSString *const MZFayeClientBayeuxConnectionTypeLongPolling = @"long-polling";
NSString *const MZFayeClientBayeuxConnectionTypeCallbackPolling = @"callback-polling";
NSString *const MZFayeClientBayeuxConnectionTypeIFrame = @"iframe";
NSString *const MZFayeClientBayeuxConnectionTypeWebSocket = @"websocket";

NSString *const MZFayeClientWebSocketErrorDomain = @"com.mzfayeclient.error";

NSTimeInterval const MZFayeClientDefaultRetryInterval = 1.0f;
NSInteger const MZFayeClientDefaultMaximumAttempts = 5;

@interface MZFayeClient ()
@property (nonatomic, readwrite, strong) SRWebSocket *webSocket;

@property (nonatomic, readwrite, strong) NSMutableSet *openChannelSubscriptions;
@property (nonatomic, readwrite, strong) NSMutableSet *pendingChannelSubscriptions;
@property (nonatomic, readwrite, strong) NSMutableDictionary *subscribedChannels;
@property (nonatomic, readwrite, strong) NSMutableDictionary *privateChannels;
@property (nonatomic, readwrite, strong) NSMutableDictionary *channelExtensions;

@property (nonatomic, readwrite, strong) NSString *clientId;

@property (nonatomic, strong) NSTimer *reconnectTimer;

@property (nonatomic, readwrite, assign) NSInteger sentMessageCount;

@property (nonatomic, readwrite, assign, getter = isConnected) BOOL connected;

@property (nonatomic, readonly, assign, getter = isWebSocketOpen) BOOL webSocketOpen;
@property (nonatomic, readonly, assign, getter = isWebSocketClosed) BOOL webSocketClosed;
@end

@implementation MZFayeClient

#pragma mark - Getters

- (NSSet *)subscriptions
{
    return [NSSet setWithArray:[self.subscribedChannels allKeys]];
}

- (NSSet *)pendingSubscriptions
{
    return [self.pendingChannelSubscriptions copy];
}

- (NSSet *)openSubscriptions
{
    return [self.openChannelSubscriptions copy];
}

- (NSDictionary *)extensions
{
    return [self.channelExtensions copy];
}

- (BOOL)isWebSocketOpen
{
    if (!self.webSocket)
        return NO;

    return self.webSocket.readyState == SR_OPEN;
}

- (BOOL)isWebSocketClosed
{
    if (!self.webSocket)
        return YES;

    return self.webSocket.readyState == SR_CLOSED;
}

#pragma mark - Dealloc

- (void)dealloc
{
    [self.subscribedChannels removeAllObjects];

    [self clearSubscriptions];

    [self invalidateReconnectTimer];
    [self disconnectFromWebSocket];
}

#pragma mark - Initializers

- (instancetype)init
{
    if (self = [super init]) {

        _channelExtensions = [NSMutableDictionary dictionary];
        _subscribedChannels = [NSMutableDictionary dictionary];
        _privateChannels = [NSMutableDictionary dictionary];
        _pendingChannelSubscriptions = [NSMutableSet set];
        _openChannelSubscriptions = [NSMutableSet set];
        _maximumRetryAttempts = MZFayeClientDefaultMaximumAttempts;
        _retryInterval = MZFayeClientDefaultRetryInterval;
        _shouldRetryConnection = YES;
        _sentMessageCount = 0;
        _retryAttempt = 0;
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url
{
    if (self = [self init]) {
        _url = url;
    }
    return self;
}

+ (instancetype)client
{
    return [[[self class] alloc] init];
}

+ (instancetype)clientWithURL:(NSURL *)url
{
    return [[[self class] alloc] initWithURL:url];
}

#pragma mark - Bayeux procotol messages

/**
 *  A handshake request MUST contain the message fields:
 *
 *  channel - value "/meta/handshake"
 *  version - The version of the protocol supported by the client.
 *
 *  supportedConnectionTypes -  An array of the connection types supported by the client for
 *  the purposes of the connection being negotiated (see section 3.4). This list MAY be a subset
 *  of the connection types actually supported if the client wishes to negotiate a specific connection type.
 */
- (void)sendBayeuxHandshakeMessage
{
    NSArray *supportedConnectionTypes = @[MZFayeClientBayeuxConnectionTypeLongPolling,
                                          MZFayeClientBayeuxConnectionTypeCallbackPolling,
                                          MZFayeClientBayeuxConnectionTypeIFrame,
                                          MZFayeClientBayeuxConnectionTypeWebSocket];

    NSMutableDictionary *message = [@{MZFayeClientBayeuxMessageChannelKey : MZFayeClientBayeuxChannelHandshake,
                              MZFayeClientBayeuxMessageVersionKey : MZFayeClientBayeuxVersion,
                              MZFayeClientBayeuxMessageMinimuVersionKey : MZFayeClientBayeuxMinimumVersion,
                              MZFayeClientBayeuxMessageSupportedConnectionTypesKey : supportedConnectionTypes
                              } mutableCopy];

    NSDictionary *extension = self.channelExtensions[@"handshake"];
    if (extension) {
        [message setObject:extension forKey:MZFayeClientBayeuxMessageExtensionKey];
    }

    [self writeMessageToWebSocket:message];
}

/**
 *  A connect request MUST contain the message fields:
 *  channel - value "/meta/connect"
 *  clientId - The client ID returned in the handshake response
 *  connectionType - The connection type used by the client for the purposes of this connection.
 */
- (void)sendBayeuxConnectMessage
{
    NSMutableDictionary *message = [@{MZFayeClientBayeuxMessageChannelKey : MZFayeClientBayeuxChannelConnect,
                              MZFayeClientBayeuxMessageClientIdKey : self.clientId,
                              MZFayeClientBayeuxMessageConnectionTypeKey : MZFayeClientBayeuxConnectionTypeWebSocket
                              } mutableCopy];

    NSDictionary *extension = self.channelExtensions[@"connect"];
    if (extension) {
        [message setObject:extension forKey:MZFayeClientBayeuxMessageExtensionKey];
    }

    [self writeMessageToWebSocket:message];
}

/**
 *  A connect request MUST contain the message fields:
 *  channel - value "/meta/connect"
 *  clientId - The client ID returned in the handshake response
 */
- (void)sendBayeuxDisconnectMessage
{
    NSDictionary *message = @{MZFayeClientBayeuxMessageChannelKey : MZFayeClientBayeuxChannelDisconnect,
                              MZFayeClientBayeuxMessageClientIdKey : self.clientId
                              };

    [self writeMessageToWebSocket:message];
}

/**
 * A subscribe request MUST contain the message fields:
 * channel - value "/meta/subscribe"
 * clientId - The client ID returned in the handshake response
 * subscription - a channel name or a channel pattern or an array of channel names and channel patterns.
 */
- (void)sendBayeuxSubscribeMessageWithChannel:(NSString *)channel
{
    NSMutableDictionary *message = [@{
                                      MZFayeClientBayeuxMessageChannelKey : MZFayeClientBayeuxChannelSubscribe,
                                      MZFayeClientBayeuxMessageClientIdKey : self.clientId,
                                      MZFayeClientBayeuxMessageSubscriptionKey : channel
                                      } mutableCopy];

    NSDictionary *extension = self.channelExtensions[channel];
    if (extension) {
        [message setObject:extension forKey:MZFayeClientBayeuxMessageExtensionKey];
    }

    [self writeMessageToWebSocket:[message copy]];

    [self.pendingChannelSubscriptions addObject:channel];
}

/**
 * An unsubscribe request MUST contain the message fields:
 * channel - value "/meta/unsubscribe"
 * clientId - The client ID returned in the handshake response
 * subscription - a channel name or a channel pattern or an array of channel names and channel patterns.
 */
- (void)sendBayeuxUnsubscribeMessageWithChannel:(NSString *)channel
{
    NSDictionary *message = @{
                              MZFayeClientBayeuxMessageChannelKey : MZFayeClientBayeuxChannelUnsubscribe,
                              MZFayeClientBayeuxMessageClientIdKey : self.clientId,
                              MZFayeClientBayeuxMessageSubscriptionKey : channel
                              };

    [self writeMessageToWebSocket:message];
}

/**
 *  A publish event message MUST contain the message fields:
 *  channel
 *  data - The message as an arbitrary JSON encoded object
 */
- (void)sendBayeuxPublishMessage:(NSDictionary *)messageDictionary withMessageUniqueID:(NSString*)messageId toChannel:(NSString *)channel usingExtension:(NSDictionary *)extension
{
    if (!(self.isConnected && self.isWebSocketOpen)) {
        [self didFailWithMessage:@"FayeClient not connected to server."];
        return;
    }

    NSMutableDictionary *message = [@{
                                      MZFayeClientBayeuxMessageChannelKey : channel,
                                      MZFayeClientBayeuxMessageClientIdKey : self.clientId,
                                      MZFayeClientBayeuxMessageDataKey : messageDictionary,
                                      MZFayeClientBayeuxMessageIdKey : messageId
                                      } mutableCopy];

    if (extension) {
        [message setObject:extension forKey:MZFayeClientBayeuxMessageExtensionKey];
    } else {
        NSDictionary *extensionForChannel = self.channelExtensions[channel];
        if (extensionForChannel) {
            [message setObject:extensionForChannel forKey:MZFayeClientBayeuxMessageExtensionKey];
        }
    }

    [self writeMessageToWebSocket:[message copy]];

}

- (void)clearSubscriptions
{
    [self.pendingChannelSubscriptions removeAllObjects];
    [self.openChannelSubscriptions removeAllObjects];
}

#pragma mark - Helper methods

- (NSString *)generateUniqueMessageId
{
    self.sentMessageCount++;

    return [[NSString stringWithFormat:@"%@", [NSNumber numberWithInteger: self.sentMessageCount]] base64String];
}

#pragma mark - Public methods

- (void)setExtension:(NSDictionary *)extension forChannel:(NSString *)channel
{
    [self.channelExtensions setObject:extension forKey:channel];
}
- (void)removeExtensionForChannel:(NSString *)channel
{
    [self.channelExtensions removeObjectForKey:channel];
}

- (void)sendMessage:(NSDictionary *)message toChannel:(NSString *)channel
{
    NSString *messageId = [self generateUniqueMessageId];
    [self sendBayeuxPublishMessage:message withMessageUniqueID:messageId toChannel:channel usingExtension:nil];
}

- (void)sendMessage:(NSDictionary *)message toChannel:(NSString *)channel usingExtension:(NSDictionary *)extension
{
    NSString *messageId = [self generateUniqueMessageId];
    [self sendBayeuxPublishMessage:message withMessageUniqueID:messageId toChannel:channel usingExtension:extension];
}

- (void)sendMessage:(NSDictionary *)message toChannel:(NSString *)channel usingExtension:(NSDictionary *)extension usingBlock:(MZFayeClientPrivateHandler)subscriptionHandler
{

    NSString *messageId = [self generateUniqueMessageId];

    if (subscriptionHandler && self.privateChannels[messageId] && messageId) {
        self.privateChannels[messageId] = subscriptionHandler;

    } else if (self.privateChannels[messageId] || !messageId) {
        return;
    }

    if (subscriptionHandler) {
        [self.privateChannels setObject:subscriptionHandler forKey:messageId];
    } else {
        [self.privateChannels setObject:[NSNull null] forKey:messageId];
    }

    [self sendBayeuxPublishMessage:message withMessageUniqueID:messageId toChannel:channel usingExtension:extension];
}

- (BOOL)connectToURL:(NSURL *)url
{
    if (self.isConnected || self.isWebSocketOpen) {
        return NO;
    }

    _url = url;
    return [self connect];
}

- (BOOL)connect
{
    if (self.isConnected || self.isWebSocketOpen) {
        return NO;
    }

    [self connectToWebSocket];

    return YES;
}

- (void)disconnect
{
    [self sendBayeuxDisconnectMessage];
}

- (void)subscribeToChannel:(NSString *)channel
{
    [self subscribeToChannel:channel usingBlock:nil];
}

- (void)subscribeToChannel:(NSString *)channel usingBlock:(MZFayeClientSubscriptionHandler)subscriptionHandler
{
    if (subscriptionHandler && self.subscribedChannels[channel] && channel) {
        self.subscribedChannels[channel] = subscriptionHandler;

    } else if (self.subscribedChannels[channel] || !channel) {
        return;
    }

    if (subscriptionHandler) {
        [self.subscribedChannels setObject:subscriptionHandler forKey:channel];
    } else {
        [self.subscribedChannels setObject:[NSNull null] forKey:channel];
    }

    if (self.isConnected) {
        [self sendBayeuxSubscribeMessageWithChannel:channel];
    }
}

- (void)unsubscribeFromChannel:(NSString *)channel
{
    if (!self.subscribedChannels[channel] || !channel) {
        return;
    }

    [self.subscribedChannels removeObjectForKey:channel];
    [self.pendingChannelSubscriptions removeObject:channel];

    if (self.isConnected) {
        [self sendBayeuxUnsubscribeMessageWithChannel:channel];
    }
}

#pragma mark - Private methods

- (void)subscribePendingSubscriptions
{
    for (NSString *channel in self.subscribedChannels) {
        if (![self.pendingChannelSubscriptions containsObject:channel] && ![self.openChannelSubscriptions containsObject:channel]) {
            [self sendBayeuxSubscribeMessageWithChannel:channel];
        }
    }
}

- (void)reconnectTimer:(NSTimer *)timer
{
    if (self.isConnected) {
        [self invalidateReconnectTimer];
    } else {
        if (self.shouldRetryConnection && self.retryAttempt < self.maximumRetryAttempts) {
            self.retryAttempt++;
            [self connect];
        } else {
            [self invalidateReconnectTimer];
        }
    }
}

- (void)invalidateReconnectTimer
{
    [self.reconnectTimer invalidate];
    self.reconnectTimer = nil;
}

- (void)reconnect
{
    if (self.shouldRetryConnection && self.retryAttempt < self.maximumRetryAttempts) {

        self.reconnectTimer = [NSTimer scheduledTimerWithTimeInterval:self.retryInterval target:self selector:@selector(reconnectTimer:) userInfo:nil repeats:NO];
    }
}

#pragma mark - SRWebSocket

- (void)writeMessageToWebSocket:(NSDictionary *)object
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];

    if (error) {
        if ([self.delegate respondsToSelector:@selector(fayeClient:didFailDeserializeMessage:withError:)]) {
            [self.delegate fayeClient:self didFailDeserializeMessage:object withError:error];
        }
    } else {
        NSString *JSON = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [self.webSocket send:JSON];
    }
}

- (void)connectToWebSocket
{
    [self disconnectFromWebSocket];

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:self.url];
    self.webSocket = [[SRWebSocket alloc] initWithURLRequest:request];
    self.webSocket.delegate = self;
    [self.webSocket open];
}

- (void)disconnectFromWebSocket
{
    self.webSocket.delegate = nil;
    [self.webSocket close];
    self.webSocket = nil;
}

- (void)didFailWithMessage:(NSString *)message
{
    if ([self.delegate respondsToSelector:@selector(fayeClient:didFailWithError:)] && message) {
        NSError *error = [NSError errorWithDomain:MZFayeClientWebSocketErrorDomain code:-100 userInfo:@{NSLocalizedDescriptionKey : message}];
        [self.delegate fayeClient:self didFailWithError:error];
    }
}

- (void)handleFayeMessages:(NSArray *)messages
{
    for (NSDictionary *message in messages) {

        if (![message isKindOfClass:[NSDictionary class]]) {
            if ([self.delegate respondsToSelector:@selector(fayeClient:didFailWithError:)]) {
                NSError *error = [NSError errorWithDomain:MZFayeClientWebSocketErrorDomain code:-100 userInfo:@{NSLocalizedDescriptionKey : @"Message is not kind of NSDicitionary class"}];
                [self.delegate fayeClient:self didFailWithError:error];
            }
            return;
        }

        MZFayeMessage *fayeMessage = [MZFayeMessage messageFromDictionary:message];

        if ([fayeMessage.channel isEqualToString:MZFayeClientBayeuxChannelHandshake]) {

            if ([fayeMessage.successful boolValue]) {
                self.retryAttempt = 0;

                self.clientId = fayeMessage.clientId;
                self.connected = YES;

                if ([self.delegate respondsToSelector:@selector(fayeClient:didConnectToURL:)]) {
                    [self.delegate fayeClient:self didConnectToURL:self.url];
                }
                [self sendBayeuxConnectMessage];
                [self subscribePendingSubscriptions];

            } else {
                [self didFailWithMessage:[NSString stringWithFormat:@"Faye client couldn't handshake with server. %@",fayeMessage.error]];
            }

        } else if ([fayeMessage.channel isEqualToString:MZFayeClientBayeuxChannelConnect]) {

            if ([fayeMessage.successful boolValue]) {
                self.connected = YES;
                [self sendBayeuxConnectMessage];
            } else {
                [self didFailWithMessage:[NSString stringWithFormat:@"Faye client couldn't connect to server. %@",fayeMessage.error]];
            }

        } else if ([fayeMessage.channel isEqualToString:MZFayeClientBayeuxChannelDisconnect]) {

            if ([fayeMessage.successful boolValue]) {
                [self disconnectFromWebSocket];

                self.connected = NO;
                [self clearSubscriptions];

                if ([self.delegate respondsToSelector:@selector(fayeClient:didDisconnectWithError:)]) {
                    [self.delegate fayeClient:self didDisconnectWithError:nil];
                }
            } else {
                [self didFailWithMessage:[NSString stringWithFormat:@"Faye client couldn't disconnect from server. %@",fayeMessage.error]];
            }

        } else if ([fayeMessage.channel isEqualToString:MZFayeClientBayeuxChannelSubscribe]) {

            [self.pendingChannelSubscriptions removeObject:fayeMessage.subscription];

            if ([fayeMessage.successful boolValue]) {
                [self.openChannelSubscriptions addObject:fayeMessage.subscription];

                if ([self.delegate respondsToSelector:@selector(fayeClient:didSubscribeToChannel:)]) {
                    [self.delegate fayeClient:self didSubscribeToChannel:fayeMessage.subscription];
                }
            } else {
                [self didFailWithMessage:[NSString stringWithFormat:@"Faye client couldn't subscribe channel %@ with server. %@",fayeMessage.subscription, fayeMessage.error]];
            }

        } else if ([fayeMessage.channel isEqualToString:MZFayeClientBayeuxChannelUnsubscribe]) {

            if ([fayeMessage.successful boolValue]) {

                [self.subscribedChannels removeObjectForKey:fayeMessage.subscription];
                [self.pendingChannelSubscriptions removeObject:fayeMessage.subscription];
                [self.openChannelSubscriptions removeObject:fayeMessage.subscription];

                if ([self.delegate respondsToSelector:@selector(fayeClient:didUnsubscribeFromChannel:)]) {
                    [self.delegate fayeClient:self didUnsubscribeFromChannel:fayeMessage.subscription];
                }

            } else {
                [self didFailWithMessage:[NSString stringWithFormat:@"Faye client couldn't unsubscribe channel %@ with server. %@",fayeMessage.subscription, fayeMessage.error]];
            }

        } else if ([self.openChannelSubscriptions containsObject:fayeMessage.channel]) {

            if (self.subscribedChannels[fayeMessage.channel] &&
                self.subscribedChannels[fayeMessage.channel] != [NSNull null]) {

                MZFayeClientSubscriptionHandler handler = self.subscribedChannels[fayeMessage.channel];
                handler(fayeMessage.data);

            } else if ([self.delegate respondsToSelector:@selector(fayeClient:didReceiveMessage:fromChannel:)]) {
                [self.delegate fayeClient:self didReceiveMessage:fayeMessage.data fromChannel:fayeMessage.channel];
            }

        } else {
            // No match for channel

            NSLog(@"Recieved message %@", fayeMessage.ext);
            //Handle For Private

            if (self.privateChannels[fayeMessage.Id] &&
                self.privateChannels[fayeMessage.Id] != [NSNull null]) {

                MZFayeClientPrivateHandler handler = self.privateChannels[fayeMessage.Id];
                handler(fayeMessage);

            }
        }

    }
}

#pragma mark - SRWebSocket Delegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    id recivedMessage = message;

    if ([recivedMessage isKindOfClass:[NSString class]]) {
        recivedMessage = [recivedMessage dataUsingEncoding:NSUTF8StringEncoding];
    }

    NSError *error = nil;
    NSArray *messages = [NSJSONSerialization JSONObjectWithData:recivedMessage options:0 error:&error];

    if (error && [self.delegate respondsToSelector:@selector(fayeClient:didFailDeserializeMessage:withError:)]) {
        [self.delegate fayeClient:self didFailDeserializeMessage:recivedMessage withError:error];
    } else {
        [self handleFayeMessages:messages];
    }

}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    [self sendBayeuxHandshakeMessage];
}
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    self.connected = NO;

    [self clearSubscriptions];

    if ([self.delegate respondsToSelector:@selector(fayeClient:didFailWithError:)]) {
        [self.delegate fayeClient:self didFailWithError:error];
    }

    [self reconnect];
}
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code
                                                     reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    self.connected = NO;

    [self clearSubscriptions];

    if ([self.delegate respondsToSelector:@selector(fayeClient:didDisconnectWithError:)]) {
        NSError *error = nil;
        if (reason) {
            error = [NSError errorWithDomain:MZFayeClientWebSocketErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey : reason}];
        }

        [self.delegate fayeClient:self didDisconnectWithError:error];
    }

    [self reconnect];

}

@end
