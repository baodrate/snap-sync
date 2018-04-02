# snap-sync
# https://github.com/wesbarnett/snap-sync
# Copyright (C) 2016, 2017 James W. Barnett

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,

PKGNAME = snap-sync
PREFIX ?= /usr
SNAPPER_CONFIG ?= /etc/sysconfig/snapper
SNAPPER_TEMPLATES ?= /etc/snapper/config-templates

BIN_DIR = $(DESTDIR)$(PREFIX)/bin
SYSTEMD_DIR = $(DESTDIR)$(PREFIX)/lib/systemd/system

.PHONY: install

install:
	@./find_snapper_config || sed -i 's@^SNAPPER_CONFIG=.*@SNAPPER_CONFIG='$(SNAPPER_CONFIG)'@g' bin/$(PKGNAME)
	@install -Dm755 bin/* -t $(BIN_DIR)/
	@install -Dm644 ./$(SNAPPER_TEMPLATES)/* -t $(DESTDIR)/$(SNAPPER_TEMPLATES)/
