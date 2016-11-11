# snap-sync
# https://github.com/wesbarnett/snap-pac
# Copyright (C) 2016 James W. Barnett

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

BIN_DIR = $(DESTDIR)$(PREFIX)/bin
SYSTEMD_DIR = $(DESTDIR)$(PREFIX)/lib/systemd/system

.PHONY: install

install:
	@install -Dm755 bin/* -t $(BIN_DIR)/
	@install -Dm755 systemd/* -t $(SYSTEMD_DIR)/
