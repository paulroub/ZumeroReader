ZumeroReader is a demo app for iPhone/iPad running iOS 6+, mainly written as example material for the
series of blog posts beginning with [Using Zumero from C#][part1].  This app is described in [Part 5][part5] of the series.

It was built using XCode 4.6.1 (the latest version at this writing), and may require modifications to run
under earlier XCode versions.  

The app itself is a minimally-modified version of XCode's stock Master/Detail app skeleton; the intent is to highlight
the [Zumero][zumero]-specific pieces, without distracting with too much (OK, any) application design or finesse.

The project structure assumes that `Zumero.framework` is available under the `../ios` folder. Adjust that path 
as necessary if you've extracted the [Zumero SDK][sdk] elsewhere.

[zumero]: http://zumero.com/
[sdk]: http://zumero.com/dev-center/
[part1]: http://www.ericsink.com/entries/rss_cat_1.html
[part5]: http://example.com/
