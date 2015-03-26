//
//  APService.h
//  APService
//
//  Created by JPush on 12-8-15.
//  Copyright (c) 2012年 HXHG. All rights reserved.
//  Version: 1.8.3

@class CLRegion;
@class UILocalNotification;

extern NSString *const kJPFNetworkDidSetupNotification;     // 建立连接
extern NSString *const kJPFNetworkDidCloseNotification;     // 关闭连接
extern NSString *const kJPFNetworkDidRegisterNotification;  // 注册成功
extern NSString *const kJPFNetworkDidLoginNotification;     // 登录成功
extern NSString *const
    kJPFNetworkDidReceiveMessageNotification;         // 收到消息(非APNS)
extern NSString *const kJPFServiceErrorNotification;  // 错误提示

@class CLLocation;
@interface APService : NSObject

#pragma - mark 基本功能
// 以下四个接口是必须调用的
+ (void)setupWithOption:(NSDictionary *)launchingOption;  // 初始化
+ (void)registerForRemoteNotificationTypes:(NSUInteger)types
                                categories:(NSSet *)categories;  // 注册APNS类型
+ (void)registerDeviceToken:(NSData *)deviceToken;  // 向服务器上报Device Token
+ (void)handleRemoteNotification:(NSDictionary *)
    remoteInfo;  // 处理收到的APNS消息，向服务器上报收到APNS消息

// 下面的接口是可选的
// 设置标签和(或)别名（若参数为nil，则忽略；若是空对象，则清空；详情请参考文档：http://docs.jpush.cn/pages/viewpage.action?pageId=3309913）
+ (void)setTags:(NSSet *)tags
               alias:(NSString *)alias
    callbackSelector:(SEL)cbSelector
              target:(id)theTarget;
+ (void)setTags:(NSSet *)tags
               alias:(NSString *)alias
    callbackSelector:(SEL)cbSelector
              object:(id)theTarget;
+ (void)setTags:(NSSet *)tags
    callbackSelector:(SEL)cbSelector
              object:(id)theTarget;
+ (void)setAlias:(NSString *)alias
    callbackSelector:(SEL)cbSelector
              object:(id)theTarget;
// 用于过滤出正确可用的tags，如果总数量超出最大限制则返回最大数量的靠前的可用tags
+ (NSSet *)filterValidTags:(NSSet *)tags;

#pragma - mark 上报日志
/**
 *  记录页面停留时间功能。
 *  startLogPageView和stopLogPageView为自动计算停留时间
 *  beginLogPageView为手动自己输入停留时间
 *
 *  @param pageName 页面名称
 *  @param seconds  页面停留时间
 */
+ (void)startLogPageView:(NSString *)pageName;
+ (void)stopLogPageView:(NSString *)pageName;
+ (void)beginLogPageView:(NSString *)pageName duration:(int)seconds;

/**
 *  开启Crash日志收集, 默认是关闭状态.
*/
+ (void)crashLogON;

/**
 *  地理位置设置
 *  为了更精确的统计用户地理位置，可以调用此方法传入经纬度信息
 *  需要链接 CoreLocation.framework 并且 #import <CoreLocation/CoreLocation.h>
 *  @param latitude 纬度.
 *  @param longitude 经度.
 *  @param location 直接传递CLLocation *型的地理信息
 */
+ (void)setLatitude:(double)latitude longitude:(double)longitude;
+ (void)setLocation:(CLLocation *)location;

#pragma - mark 本地通知
/**
* 本地推送，最多支持64个
* @param fireDate 本地推送触发的时间
* @param alertBody 本地推送需要显示的内容
* @param badge 角标的数字。如果不需要改变角标传-1
* @param alertAction 弹框的按钮显示的内容（IOS 8默认为"打开",其他默认为"启动"）
* @param notificationKey 本地推送标示符
* @param userInfo 自定义参数，可以用来标识推送和增加附加信息
* @param soundName 自定义通知声音，设置为nil为默认声音

* IOS8新参数
* @param region 自定义参数
* @param regionTriggersOnce 自定义参数
* @param category 自定义参数
*/
+ (UILocalNotification *)setLocalNotification:(NSDate *)fireDate
                                    alertBody:(NSString *)alertBody
                                        badge:(int)badge
                                  alertAction:(NSString *)alertAction
                                identifierKey:(NSString *)notificationKey
                                     userInfo:(NSDictionary *)userInfo
                                    soundName:(NSString *)soundName;

+ (UILocalNotification *)setLocalNotification:(NSDate *)fireDate
                                    alertBody:(NSString *)alertBody
                                        badge:(int)badge
                                  alertAction:(NSString *)alertAction
                                identifierKey:(NSString *)notificationKey
                                     userInfo:(NSDictionary *)userInfo
                                    soundName:(NSString *)soundName
                                       region:(CLRegion *)region
                           regionTriggersOnce:(BOOL)regionTriggersOnce
                                     category:(NSString *)category
    NS_AVAILABLE_IOS(8_0);

/**
* 本地推送在前台推送。默认App在前台运行时不会进行弹窗，在程序接收通知调用此接口可实现指定的推送弹窗。
* @param notification 本地推送对象
* @param notificationKey 需要前台显示的本地推送通知的标示符
*/
+ (void)showLocalNotificationAtFront:(UILocalNotification *)notification
                       identifierKey:(NSString *)notificationKey;
/**
* 删除本地推送
* @param notificationKey 本地推送标示符
* @param myUILocalNotification 本地推送对象
*/
+ (void)deleteLocalNotificationWithIdentifierKey:(NSString *)notificationKey;
+ (void)deleteLocalNotification:(UILocalNotification *)localNotification;

/**
* 获取指定通知
* @param notificationKey 本地推送标示符
* @return  本地推送对象数组,[array count]为0时表示没找到
*/
+ (NSArray *)findLocalNotificationWithIdentifier:(NSString *)notificationKey;

/**
* 清除所有本地推送对象
*/
+ (void)clearAllLocalNotifications;

#pragma - mark 设置Badge
/**
 *  set setBadge
 *  @param value 设置JPush服务器的badge的值
 *  本地仍须调用UIApplication:setApplicationIconBadgeNumber函数,来设置脚标
 */
+ (BOOL)setBadge:(NSInteger)value;
/**
 *  set setBadge
 *  @param value 清除JPush服务器对badge值的设定.
 *  本地仍须调用UIApplication:setApplicationIconBadgeNumber函数,来设置脚标
 */

+ (void)resetBadge;

/**
 *  get RegistrationID
 */
+ (NSString *)registrationID;

#pragma - mark 打印日志信息配置
/**
 *  setDebugMode获取更多的Log信息
 *  开发过程中建议开启DebugMode
 *
 *  setLogOFF关闭除了错误信息外的所有Log
 *  发布时建议开启LogOFF用于节省性能开销
 *
 *  默认为不开启DebugLog,只显示基本的信息
 */
+ (void)setDebugMode;
+ (void)setLogOFF;
@end
