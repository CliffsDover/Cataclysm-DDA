# -*- coding: utf-8 -*-
import polib, sys
po = polib.pofile( sys.argv[1] )
for entry in po:
        print "[%s] %s" % ( entry.msgid, entry.msgstr )
