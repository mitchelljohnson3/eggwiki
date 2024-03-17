#!/usr/bin/env python

import os
import re
from collections import OrderedDict

from eggwiki.server import storage, app
from eggwiki.util import (
    split_path,
    join_path,
)
from eggwiki.helper import (
    get_pagename,
)


class SidebarNavigation:
    AXT_HEADING = re.compile(
        r' {0,3}(#{1,6})(?!#+)(?: *\n+|' r'\s+([^\n]*?)(?:\n+|\s+?#+\s*\n+))'
    )
    SETEX_HEADING = re.compile(r'([^\n]+)\n *(=|-){2,}[ \t]*\n+')

    def __init__(self, path: str = "/"):
        self.path = path if app.config["RETAIN_PAGE_NAME_CASE"] else path.lower()
        self.path_depth = len(split_path(self.path))
        try:
            self.max_depth = int(app.config["SIDEBAR_MENUTREE_MAXDEPTH"])
        except ValueError:
            self.max_depth = None
        self.mode = app.config["SIDEBAR_MENUTREE_MODE"]
        # TODO load configs (yaml header in page?) (sidebar.yaml?)
        # TODO check for cached pages
        # load pages
        if self.mode == "":
            self.tree = None
        else:
            self.tree = OrderedDict()
            self.load()
            self.tree = self.order_tree(self.tree)

    def read_header(self, filename):
        filehead = storage.load(filename, size=512)
        # find first markdown header in filehead
        header = [line for (_, line) in self.AXT_HEADING.findall(filehead)]
        header += [line for (line, _) in self.SETEX_HEADING.findall(filehead)]
        if len(header):
            return header[0]
        return None

    def order_tree(
        self,
        tree: OrderedDict,
    ):
        # convert OrderedDict into list
        entries = list(tree.items())
        # decide sort_key lambda on mode
        sort_key = None
        if self.mode in ["DIRECTORIES_GROUPED"]:
            sort_key = lambda k: (len(k[1]["children"]) == 0, k[0])
        # sort entries
        filtered_list = sorted(entries, key=sort_key)
        # filter entries
        if self.mode in ["DIRECTORIES_ONLY"]:
            filtered_list = [
                x for x in filtered_list if len(x[1]["children"]) > 0
            ]
        # after filtering and ordering: back to OrderedDict
        stree = OrderedDict(filtered_list)
        # recursivly take care of the child nodes
        for key, values in stree.items():
            if values["children"]:
                stree[key]["children"] = self.order_tree(
                    values["children"],
                )
        return stree

    def add_node(self, tree, prefix, parts, header=None):
        # handle max_depth
        if (
            self.max_depth
            and len(prefix) + len(parts) > self.path_depth + self.max_depth
        ):
            return
        if parts[0] not in tree:
            tree[parts[0]] = {
                "children": OrderedDict(),
                "path": get_pagename(
                    join_path(prefix + parts),
                    full=True,
                    header=header if len(parts) == 1 else None,
                ),
                "header": get_pagename(
                    join_path(prefix + parts),
                    full=False,
                    header=header if len(parts) == 1 else None,
                ),
            }
        if len(parts) > 1:
            self.add_node(
                tree[parts[0]]["children"], prefix + [parts[0]], parts[1:]
            )

    def load(self):
        files, _ = storage.list(p=self.path)

        entries = []
        for filename in [
            f for f in files if f.endswith(".md")
        ]:  # filter .md files
            if self.path is not None:
                filename = os.path.join(self.path, filename)
            parents = split_path(filename)[:-1]
            # ensure all parents are in the entries
            for i in range(len(parents)):
                pp = join_path(parents[0 : i + 1])
                entries.append(pp)
            entries.append(filename)
        entries = sorted(list(set(entries)))

        for entry in entries:
            header = None
            if entry.endswith(".md"):
                header = self.read_header(entry)
                entry = entry[:-3]
            parts = split_path(entry)
            self.add_node(self.tree, [], parts, header)

    def query(self):
        return self.tree


# vim: set et ts=8 sts=4 sw=4 ai:
