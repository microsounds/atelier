-- ~/.config/chromium/omnibox.sql: persistent omnibox settings

INSERT OR REPLACE INTO keywords (id, short_name, keyword, favicon_url, url, is_active)
-- internal chromium search shortcuts
	VALUES (0, 'Bookmarks', '@bookmarks', 'about:blank', 'chrome://bookmarks/?={searchTerms}', 1),
	       (1, 'History', '@history', 'about:blank', 'chrome://history/?={searchTerms}', 1),
	       (2, 'Tabs', '@tabs', 'about:blank', 'chrome://tabs/?={searchTerms}', 1),
-- 3rd party site shortcuts
	       (3, 'YouTube', 'youtube.com', 'about:blank', 'https://www.youtube.com/results?search_query={searchTerms}', 1),
	       (4, 'Yandex', 'yandex.com', 'about:blank', 'https://www.yandex.com/search/?text={searchTerms}', 1),
	       (5, 'Nyaa', 'nyaa.si', 'about:blank', 'https://nyaa.si/?q={searchTerms}', 1),
	       (6, 'Twitter', 'twitter.com', 'about:blank', 'https://twitter.com/search?q={searchTerms}', 1),
	       (7, 'Wikipedia', 'wikipedia.com', 'about:blank', 'https://en.wikipedia.org/wiki/Special:Search?search={searchTerms}', 1),
	       (8, 'Google Translate', 'translate.google.com', 'about:blank', 'https://translate.google.com/source=osdd#auto|auto|{searchTerms}', 1),
	       (8, 'Google Maps', 'maps.google.com', 'about:blank', 'https://www.google.com/maps?q={searchTerms}', 1),
	       (9, 'GitHub', 'github.com', 'about:blank', 'https://github.com/search?q={searchTerms}&type=repositories', 1),
-- anime and weeb adjacent
	       (10, 'Niconico', 'nicovideo.jp', 'about:blank', 'https://www.nicovideo.jp/search/{searchTerms}', 1),
	       (11, 'nhentai', 'nhentai.net', 'about:blank', 'https://nhentai.net/search/?q={searchTerms}', 1),
	       (12, 'pixiv', 'pixiv.net', 'about:blank', 'https://www.pixiv.net/en/tags/{searchTerms}', 1),
	       (13, 'Gelbooru', 'gelbooru.com', 'about:blank', 'http://gelbooru.com/index.php?page=post&s=list&tags={searchTerms}', 1),
	       (14, 'MangaDex', 'mangadex.org', 'about:blank', 'https://mangadex.org/search?q={searchTerms}', 1),
-- shopping sites
	       (15, 'AliExpress', 'aliexpress.com', 'about:blank', 'http://www.aliexpress.com/wholesale?SearchText={searchTerms}', 1),
	       (16, 'Amazon', 'amazon.com', 'about:blank', 'https://www.amazon.com/s?k={searchTerms}', 1),
	       (17, 'Amazon.jp', 'amazon.co.jp', 'about:blank', 'https://www.amazon.co.jp/s?k={searchTerms}', 1),
	       (18, 'eBay', 'ebay.com', 'about:blank', 'https://www.ebay.com/sch/i.html?_nkw={searchTerms}', 1),
-- 4chan archiver searches
	       (19, '4chan', 'find.4chan.org', 'about:blank', 'https://find.4channel.org/?q={searchTerms}', 1),
	       (20, 'desuarchive /g/', 'desuarchive.org/g/', 'about:blank', 'https://desuarchive.org/g/search/text/{searchTerms}', 1),
	       (21, 'desuarchive /a/', 'desuarchive.org/a/', 'about:blank', 'https://desuarchive.org/a/search/text/{searchTerms}', 1),
	       (22, '4plebs /s4s/', '4plebs.org/a/', 'about:blank', 'https://archive.4plebs.org/s4s/search/text/{searchTerms}', 1),
	       (23, '4plebs /o/', '4plebs.org/o/', 'about:blank', 'https://archive.4plebs.org/o/search/text/{searchTerms}', 1),
	       (24, 'arch.b4k.co /v/', 'arch.b4k.co/', 'about:blank', 'https://arch.b4k.co/v/search/text/{searchTerms}', 1),
	       (25, 'warosu.org /fa/', 'warosu.org/fa/', 'about:blank', 'https://warosu.org/fa/?task=search&search_text={searchTerms}', 1),
	       (26, 'warosu.org /ck/', 'warosu.org/ck/', 'about:blank', 'https://warosu.org/ck/?task=search&search_text={searchTerms}', 1),
	       (27, 'warosu.org /jp/', 'warosu.org/jp/', 'about:blank', 'https://warosu.org/jp/?task=search&search_text={searchTerms}', 1);
