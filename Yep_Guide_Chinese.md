# Yep 代码入门指南

> 请使用最新的 Cocoapods（version 0.39.0）和 Xcode 7.2 进行编译并运行。

## Intro

Yep 是一款非常小巧而轻量化的社交 App，围绕「遇见天才」这个主题，让用户去找到领域中的精英或者是正在一起学习的人。

Yep 的底层的架构也非常得清晰易懂，是我们经常使用的 MVC 架构。在文件中分别对应了 `Realm/Models.swift`、`Views` 文件夹以及 `ViewControllers` 文件夹。下面让我们一起了解一下 Yep 的工程目录。

## Model

Model 层使用了 [Realm](https://realm.io) 做数据持久化处理。所对应的 `Realm/Models.swift` 中可以看到对用户、用户技能、消息和订阅流等做了比较多的处理。对于数据库的增删改查也在该文件中有所体现，在这里不详细展开，可以直接参考代码。

## UI（View & ViewController）

Yep 的整个视图跳转基本通过 Storyboard 来组织逻辑。在 `Main.storyboard` 中可以看到主要的界面跳转以及连接的实现方式。利用 Storyboard References 的新特性，将不同的 ViewController 分散到不同的功能文件夹的 Storyboard 中，整个 `Main.storyboard` 显得不再臃肿，也同时便于版本管理。

与此同时，还可以注意一下有很多的 View 都实现了 `@IBDesignable`，在 Interface Builder 上我们能够可视化界面的变化并且对界面进行操作。

## Activity

在 Yep 中，我们使用了 [MonkeyKing](https://github.com/nixzhu/MonkeyKing/) 来做不集成微信、微博等 SDK 而使用系统的 `UIActivityViewController` 的分享。使用方法非常简单，参看 `Activities/WeChatActivity.swift`。

## Service

所有的 Service 均在 `Services` 文件夹下。可以看到，主要的服务分为以下几大块：

1. 用户基础操作服务（`YepService.swift`）：登录、验证手机
2. 消息同步操作（`YepServiceSync.swift`）：技能、未读信息
3. 网络请求（`YepNetworking.swift`）：网络请求、JSON 拆解包
4. 数据下载（`YepDownloader.swift`）：下载音视频
5. 消息订阅（`FayeService.swift`）
6. 云端存储服务（`YepStorageService.swift`）
7. 音视处理（`YepAudioService.swift`）：基于 AVFundation 和 AudioToolbox，录音、播放
8. 位置服务（`YepLocationService.swift`）
9. 社交信息服务（`SocialWorkService.swift`）：获取 GitHub、Dribbble 和 Instagram 的信息
10. `OpenGraphService`：探测 iBooks、App、Apple Music 等信息

## Performance

对于性能调优，Yep 做了对图像信息的缓存处理（`Caches` 文件夹）。更多性能处理可参看[这个 Slide](https://github.com/atConf/atswift-2016-resources/tree/master/keynotes/周楷雯_Faster%20iOS%20App.key)。

## License

MIT