# Yep

A community where geniuses meet

https://soyep.com

![](https://cloud.githubusercontent.com/assets/1941540/12776320/05da093e-ca90-11e5-8b6f-a50ec826cf9e.jpg)

# Yep: Project Introductory Guide

> Please build with the latest CocoaPods v0.39.0 and Xcode 7.2.

## Intro

Yep is a nifty and lightweight social networking app, revolving around the theme of "Meeting Genius", enabling users to find experts or other learners of a particular domain.

The project's architecture is easy to understand, following the common software pattern MVC, separating UI, business logic and data model. Now, let's dive into the Yep project!

## Model

[Realm](https://realm.io) helps us a lot with data persistence. You can checkout the `Realm/Models.swift` file to learn how we add, modify, update or delete data in Realm database.

## UI(View & ViewController)

We use Storyboard to join different view controllers together. You can take a glance at the `Main.storyboard` file. Thanks to the **Storyboard References** feature, we break up storyboards into a set of smaller storyboards. Easy to maintain and handle `.storyboard` files under source control, right?

At the same time, you should notice that some views are `@IBDesignable`. You can use Interface Builder, drag the view out and observe changes.

## Activity

Without integrating WeChat or Weibo SDK, Yep uses [MonkeyKing](https://github.com/nixzhu/MonkeyKing/) with the native `UIActivityViewController`. See `Activities/WeChatActivity.swift`.

## Service

You can find all Services under `Services` directory. Our services are divided into following parts:

1. User-related operation service (`YepService.swift`): Sign-in, phone verification
2. User operation service (`YepServiceSync.swift`): Skills, messages
3. Network requests service (`YepNetworking.swift`): Network requests, JSON parsing/serialization
4. Data download service (`YepDownloader.swift`): Audio, video downloading
5. Feeds (`FayeService.swift`)
6. Cloud storage service (`YepStorageService.swift`)
7. Audio and video service (`YepAudioService.swift`): Based on AVFoundation and AudioToolbox
8. Location service (`YepLocationService.swift`)
9. Social info service (`SocialWorkService.swift`): Get user's GitHub, Dribbble and Instagram info
10. Open Graph Service (`OpenGraphService.swift`): Get iBooks, App and Apple Music info

## Performance

In order to improve FPS rate, we do image caching (`Caches` folder).

Wants to learn more? View [this slide](https://github.com/atConf/atswift-2016-resources/tree/master/keynotes/周楷雯_Faster%20iOS%20App.key).

## Development

If you like to join us developing Yep, fork this repo and use git flow on `develop` branch to create a new branch for your developing. When you finish, send a pull request.

Please ensure each commit is minimized for code review.

Please stop using simulator's waterfall image as your avatar.

You can track our progress at [Trello](https://trello.com/b/gxmPfiAd/yep-ios).

## License

MIT

### [中文指南](Yep_Guide_Chinese.md)
