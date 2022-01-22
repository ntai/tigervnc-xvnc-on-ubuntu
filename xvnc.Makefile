.PHONY: install preinstall

MAKE_DEFAULTS := -j 4
TIGERVNC_SRCDIR := $(PWD)/tigervnc
TIGERVNC_BUILDDIR := $(PWD)/build
TIGERVNC_REPO := https://github.com/TigerVNC/tigervnc.git
TIGERVNC_BRANCH := 1.12-branch
PREFIX=/usr/local/tigervnc/tigervnc-1.12.0
EXECUTABLES := vncconfig vncpasswd v0vncserver Xvnc
ULBEXECS := $(foreach fname,$(EXECUTABLES),$(addprefix /usr/local/bin/,$(fname)))
TIGEREXECS := $(foreach fname,$(EXECUTABLES),$(addprefix $(PREFIX)/bin/,$(fname)))

default: $(PREFIX)/bin/Xvnc $(PREFIX)/libexec/vncserver

$(PREFIX)/bin/Xvnc: $(TIGERVNC_BUILDDIR)/unix/xserver/hw/vnc/Xvnc
	cd $(TIGERVNC_BUILDDIR)/unix/xserver && sudo make install

$(PREFIX)/libexec/vncserver: $(TIGERVNC_BUILDDIR)/unix/vncserver/vncserver
	cd $(TIGERVNC_BUILDDIR)/unix && sudo make install

build/unix/vncserver/vncserver: build/Makefile
	cd build && make $(MAKE_DEFAULTS)

build/Makefile: build
	cd build && cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=$(PREFIX) $(TIGERVNC_SRCDIR)

tigervnc:
	git clone --branch $(TIGERVNC_BRANCH) $(TIGERVNC_REPO)

build: tigervnc
	sudo apt install -y --no-install-recommends cmake libjpeg8 zlib1g libc6 libssl1.1 libpixman-1-0 libxfont2 libxau6 libxdmcp6 libstdc++6 libbz2-1.0 libfontenc1 libfreetype6 libbsd0 libglx0 libglvnd0 libpng16-16 libx11-6 libxcb1 libx11-dev libfltk1.3 libfltk1.3-dev libjpeg-turbo8-dev libpixman-1-dev libgettextpo-dev libgnutls28-dev gettext libpam0g-dev libxdo-dev libxdamage-dev libxfixes-dev libxrandr-dev libxtst-dev xorg-server-source xz-utils autoconf xutils-dev libtool libgl-dev libglx-dev libxkbfile-dev libxfont-dev  libgl1-mesa-dri libglu1-mesa-dev freeglut3-dev mesa-common-dev
	mkdir build

build/unix/xserver: build/unix/vncserver/vncserver
	cd $(TIGERVNC_BUILDDIR)/unix && xz -d -c /usr/src/xorg-server.tar.xz  | tar xf -
	mv $(TIGERVNC_BUILDDIR)/unix/xorg-server $(TIGERVNC_BUILDDIR)/unix/xserver
	-cd $(TIGERVNC_BUILDDIR)/unix/xserver && patch -p1 < $(TIGERVNC_SRCDIR)/unix/xserver120.patch

build/unix/xserver/hw/vnc: build/unix/xserver
	rsync -a $(TIGERVNC_SRCDIR)/unix/xserver/hw/vnc/ $(TIGERVNC_BUILDDIR)/unix/xserver/hw/vnc/

build/unix/xserver/configure: build/unix/xserver/hw/vnc
	cd $(TIGERVNC_BUILDDIR)/unix/xserver && autoreconf -fiv

build/unix/xserver/Makefile: build/unix/xserver/configure
	cd $(TIGERVNC_BUILDDIR)/unix/xserver && ./configure --prefix $(PREFIX) \
	--with-pic \
	--without-dtrace \
	--disable-static \
	--disable-dri \
	--disable-xinerama \
	--disable-xvfb \
	--disable-xnest \
	--disable-xorg \
	--disable-dmx \
	--disable-xwin \
	--disable-xephyr \
	--disable-kdrive \
	--disable-config-hal \
	--disable-config-udev \
	--disable-dri2 \
	--enable-glx \
	--with-default-font-path="catalogue:/etc/X11/fontpath.d,built-ins" \
	--with-xkb-path=/usr/share/X11/xkb \
	--with-xkb-output=/var/lib/xkb \
	--with-xkb-bin-directory=/usr/bin \
	--with-serverconfig-path=/usr/lib64/xorg

$(TIGERVNC_BUILDDIR)/unix/xserver/hw/vnc/Xvnc: build/unix/xserver/Makefile
	cd $(TIGERVNC_BUILDDIR)/unix/xserver &&  make $(MAKE_DEFAULTS) TIGERVNC_SRCDIR=$(TIGERVNC_SRCDIR) TIGERVNC_BUILDDIR=$(TIGERVNC_BUILDDIR)

$(ULBEXECS): /usr/local/bin/%: $(PREFIX)/bin/%
	cd /usr/local/bin && sudo ln -s $<

$(TIGEREXECS): 
	cd $(TIGERVNC_BUILDDIR)/unix && sudo make install
	cd $(TIGERVNC_BUILDDIR)/unix/xserver && sudo make install

install: $(ULBEXECS)
