/**
    Cache used to store rendered blog post HTML content.

    Assumes that rendering is done from Markdown sources.
 */
module mood.cache.html;

import mood.cache.core;

/// Cache used to store rendered blog post HTML content.
struct HTMLCache
{
    import vibe.inet.path : Path;

    /// cached blog post HTML
    Cache data;
    alias data this;

    /**
        Renders given Markdown source and regenerates post cache to
        include that new entry

        Params:
            key = relative URL of the blog post
            md_source = Markdown source of the blog post
     */
    void render(string key, string md_source)
    {
        import vibe.textfilter.markdown;

        auto html = filterMarkdown(md_source, MarkdownFlags.backtickCodeBlocks);
        this.data.replaceWith(this.add(key, html));
    }

    /**
        Bulk Markdown source renderer

        Completely replaces current cache with the new one generated based on
        full cache of Markdown sources. Considerably more efficient than calling
        per-entry `render` many times because new cache will be allocated only
        one time.

        Params:
            md_cache = cache of Markdown sources
     */
    void render(ref Cache md_cache)
    {
        import vibe.textfilter.markdown;
        import std.exception : assumeUnique;

        string[string] new_data;

        foreach (url, data; md_cache.posts_by_url)
            new_data[url] = filterMarkdown(data, MarkdownFlags.backtickCodeBlocks);

        auto new_cache = new immutable CacheData(assumeUnique(new_data));
        this.data.replaceWith(new_cache);
    }
}

unittest
{
    HTMLCache html;

    html.render("/url", "# abcd");
    assert (html.posts_by_url["/url"] == "<h1> abcd</h1>\n");

    Cache md;
    md.replaceWith(md.add("/block/1", "# a"));
    md.replaceWith(md.add("/block/2", "## b"));
    md.replaceWith(md.add("/block/3", "### c"));

    html.render(md);
    assert (html.posts_by_url["/block/1"] == "<h1> a</h1>\n");
    assert (html.posts_by_url["/block/2"] == "<h2> b</h2>\n");
    assert (html.posts_by_url["/block/3"] == "<h3> c</h3>\n");
}