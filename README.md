Shiver
======

> Be in the know when your favorite streamers go live on Twitch, right in your
menu bar.

Shiver was created to scratch an itch. Twitch has some features that might be cool
to some when it comes to being notified of when streams go live, like email. But
that's tough, because I hate email notifications. Likewise, their iOS
application has a good (albeit janky at times) push notification experience, but
when I want to watch a stream, I don't want to necessarily watch it on my
iPhone.

Enter Shiver.

Building Shiver
---------------

Shiver will eventually be on the App Store. But if you want to get in on the
action now, there are a couple of prerequisites. Make sure you have, Xcode
installed. I currently use 4.6.2. After that, install
[CocoaPods](http://cocoapods.org), it's as "easy" as this:
  
    $ gem install cocoapods
    $ pod setup

Then, while in the project's directory:

    $ pod install
    $ open Shiver.xcodeworkspace

You should be able to build the application. If you're having any problems,
please be so kind and [file an
issue](https://github.com/bryanveloso/shiver/issues/new).

Some Notes
----------

* As of the current build, the design is not complete. 
* Authentication is done via OAuth in Shiver's Preferences panel, but it hasn't 
been thoroughly tested beyond it "just working" for me. 
* Shiver lives in your menu bar. Currently, it'll check for new streams every 
5 minutes and notify you via OS X's Notification Center if a streamer you 
follow goes live; In future versions that'll be configurable. If you want to test
out the notifications, head on over to Twitch, follow somebody new and refresh
the stream list.

