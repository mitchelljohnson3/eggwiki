# This file contains both the "plugin spec" for An Otter Wiki, and several
# plugins included with the app itself. For now this is a proof of concept
# that will be expanded in the future.
#
# See docs/plugin_examples for examples.
#

import pluggy
import re
import urllib.parse

hookspec = pluggy.HookspecMarker("eggwiki")
hookimpl = pluggy.HookimplMarker("eggwiki")


class eggwikiPluginSpec:
    """A hook specification namespace for eggwiki."""

    @hookspec
    def renderer_markdown_preprocess(self, md):
        """
        This hook receives a markdown string, and can transform it any way it
        sees fit. It is called before the markdown is rendered into HTML.

        If multiple hooks exits, they will be chained, the output of
        each hook will be fed into the next one.
        """

    @hookspec
    def renderer_html_postprocess(self, html):
        """
        This hooks receive a html string. It is called after the pages
        markdown has been rendered into html.
        """

    @hookspec
    def page_view_htmlcontent_postprocess(self, html, page):
        """
        This hooks receives a html string containing the page content.
        """


class WikiLinkPlugin:
    """This plugin preprocesses links in the [[WikiLink]] style."""

    wiki_link_outer = re.compile(
        r'\[\['
        r'([^\]]+)'
        r'\]\](?!\])'  # [[  # ...  # ]]
    )
    wiki_link_inner = re.compile(r'([^\|]+)\|?(.*)')

    @hookimpl
    def renderer_markdown_preprocess(self, md):
        """
        Will turn
            [[Page]]
            [[Title|Link]]
        into
            [Page](/Page)
            [Title](/Link)
        """
        for m in self.wiki_link_outer.finditer(md):
            title, link = self.wiki_link_inner.findall(m.group(1))[0]
            if link == '':
                link = title
            if not link.startswith("/"):
                link = f"/{link}"
            # quote link (and just in case someone encoded already: unquote)
            link = urllib.parse.quote(urllib.parse.unquote(link), safe="/#")
            md = md.replace(m.group(0), f'[{title}]({link})')

        return md


# pluggy doesn't by default handle chaining the output of one plugin into
# another, so this is a small utility function to do this.
# this utility function will chain the result of each hook into the first
# argument of the next hook.
def chain_hooks(hook_name, value, *args, **kwargs):
    for impl in getattr(plugin_manager.hook, hook_name).get_hookimpls():
        fn = getattr(impl, 'function')
        value = fn(value, *args, **kwargs)
    return value


# this plugin_manager is exported so the normal pluggy API can be used in
# addition to the utility function above.
plugin_manager = pluggy.PluginManager("eggwiki")
plugin_manager.add_hookspecs(eggwikiPluginSpec)
plugin_manager.register(WikiLinkPlugin())
plugin_manager.load_setuptools_entrypoints("eggwiki")
