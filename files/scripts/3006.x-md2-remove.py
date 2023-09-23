#!/usr/bin/env python3
import lief

lib = lief.parse("/lib64/libldap.so.2")
sym = next(i for i in lib.imported_symbols if i.name == "EVP_md2")
lib.remove_dynamic_symbol(sym)
lib.write("/opt/saltstack/salt/lib//libldap.so.2")

