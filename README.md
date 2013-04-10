ZumeroReader is a demo app for iPhone/iPad running iOS 6+, mainly written as example material for the
series of blog posts beginning with [Using Zumero from C#][part1].  This app is described in [Part 5][part5] of the series.

It was built using XCode 4.6.1 (the latest version at this writing), and may require modifications to run
under earlier XCode versions.  

The app itself is a minimally-modified version of XCode's stock Master/Detail app skeleton; the intent is to highlight
the [Zumero][zumero]-specific pieces, without distracting with too much (OK, any) application design or finesse.

The project structure assumes that `Zumero.framework` is available under the `../ios` folder. Adjust that path 
as necessary if you've extracted the [Zumero SDK][sdk] elsewhere.

As-checked-in, the app syncs with Eric Sink's Zumero RSS instance. Unsurprisingly, you're not an admin there.  You'll
want to set up your own [Zumero][zumero] instance, as described in the [blog series][part1], and modify [`ZRConfig::server`][servervar]
accordingly, to add/update your own list of feeds.

[zumero]: http://zumero.com/
[sdk]: http://zumero.com/dev-center/
[part1]: http://www.ericsink.com/entries/rss_cat_1.html
[part5]: http://blog.roub.net/2013/04/zumero-background-sync-in-objective-c.html
[servervar]: https://github.com/paulroub/ZumeroReader/blob/master/ZumeroReader/ZRConfig.m#L14
