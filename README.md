#Yep

技能社交，科技面基

因为 Swift 和 Objc 的项目需要一些 Hack 才能一起工作.


##1.JPushSDK

这个是超级大坑
基本上需要你把 Pod 装一下 JPushSDK 然后再把它的 .a 文件放进去项目里面。

##2.Faye

MZFayeClient 需要直接 Hack 下他的 Pod 里的源文件，解决找不到 SRWebSocket.h 的问题。

```objective-c
//MZFayeClient.h
#import <SocketRocket/SRWebSocket.h>
```
