# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-video/totem/totem-2.30.0-r1.ebuild,v 1.1 2010/06/13 20:36:55 pacho Exp $

EAPI="2"
WANT_AUTOMAKE="1.11"

inherit autotools eutils gnome2 multilib python

DESCRIPTION="Media player for GNOME"
HOMEPAGE="http://gnome.org/projects/totem/"

LICENSE="GPL-2 LGPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"

# FIXME: Enable for now python USE flag per bug #316409
# this change should only be noticed by people not following current
# current linux profiles default
IUSE="bluetooth debug doc galago lirc nsplugin tracker +youtube" #iplayer nautilus +python vala zeroconf

# TODO:
# Cone (VLC) plugin needs someone with the right setup (remi ?)
# check gmyth requirement ? -> waiting for updates in tree
# coherence plugin not enabled until we have deps in tree
# vala ( dev-lang/vala ) requires 0.7.5
RDEPEND=">=dev-libs/glib-2.25.9
	>=x11-libs/gtk+-2.90.3:3
	>=gnome-base/gconf-2.0
	>=dev-libs/totem-pl-parser-2.29.1
	dev-libs/libpeas
	>=x11-themes/gnome-icon-theme-2.16
	x11-libs/cairo
	>=dev-libs/libxml2-2.6
	>=dev-libs/dbus-glib-0.71
	>=media-libs/gstreamer-0.10.28.1
	>=media-libs/gst-plugins-good-0.10
	>=media-libs/gst-plugins-base-0.10.26
	>=media-plugins/gst-plugins-gconf-0.10

	>=media-plugins/gst-plugins-taglib-0.10
	>=media-plugins/gst-plugins-gio-0.10
	>=media-plugins/gst-plugins-pango-0.10
	>=media-plugins/gst-plugins-x-0.10
	>=media-plugins/gst-plugins-meta-0.10-r2

	x11-libs/libSM
	x11-libs/libX11
	x11-libs/libXtst
	>=x11-libs/libXrandr-1.1.1
	>=x11-libs/libXxf86vm-1.0.1

	nsplugin? ( >=x11-misc/shared-mime-info-0.22 )

	bluetooth? ( || (
		net-wireless/bluez
		net-wireless/bluez-libs ) )
	galago? ( >=dev-libs/libgalago-0.5.2 )
	lirc? ( app-misc/lirc )
	tracker? ( >=app-misc/tracker-0.8.1 )
	youtube? (
		>=dev-libs/libgdata-0.4.0
		media-plugins/gst-plugins-soup )"
# FIXME: no gtk+:3 version of libnautilus-extension
#	nautilus? ( >=gnome-base/nautilus-2.10 )

# FIXME: not tested
#	vala? ( >=dev-lang/vala-0.7.5 )

# FIXME: disabled upstream (no pygtk for gtk3
#	python? (
#		dev-lang/python[threads]
#		>=dev-python/pygtk-2.12
#		dev-python/pyxdg
#		dev-python/gst-python
#		dev-python/dbus-python
#		dev-python/gconf-python )
#	iplayer? (
#		dev-python/pygobject
#		dev-python/pygtk
#		dev-python/httplib2
#		dev-python/feedparser
#		dev-python/beautifulsoup )

# FIXME: freezes totem
#	zeroconf? ( >=net-libs/libepc-0.3 )
DEPEND="${RDEPEND}
	sys-devel/gettext
	x11-proto/xproto
	x11-proto/xextproto
	x11-proto/xf86vidmodeproto
	app-text/scrollkeeper
	gnome-base/gnome-common
	app-text/gnome-doc-utils
	>=dev-util/intltool-0.40
	>=dev-util/pkgconfig-0.20
	dev-util/gtk-doc-am
	doc? ( >=dev-util/gtk-doc-1.11 )
	app-text/docbook-xml-dtd:4.5"
# docbook-xml-dtd is needed for user doc

DOCS="AUTHORS ChangeLog NEWS README TODO"

pkg_setup() {
	G2CONF="${G2CONF}
		--disable-scrollkeeper
		--disable-schemas-install
		--disable-static
		--disable-vala
		--with-dbus
		--with-smclient
		--enable-easy-codec-installation
		$(use_enable nsplugin browser-plugins)"

	# Plugin configuration
	G2CONF="${G2CONF}
		BROWSER_PLUGIN_DIR=/usr/$(get_libdir)/nsbrowser/plugins"

	local plugins="thumbnail,screensaver,ontop,gromit,media-player-keys,properties,sidebar-test,skipto,screenshot,brasero-disc-recorder"
	use bluetooth && plugins="${plugins},bemused"
	use galago && plugins="${plugins},galago"
	#use iplayer && plugins="${plugins},iplayer"
	use lirc && plugins="${plugins},lirc"
	#use python && plugins="${plugins},pythonconsole,jamendo,opensubtitles,dbus-service"
	use tracker && plugins="${plugins},tracker"
	use youtube && plugins="${plugins},youtube"
	#use zeroconf && plugins="${plugins},publish"

	G2CONF="${G2CONF} --with-plugins=${plugins}"

	G2CONF="${G2CONF}
		$(use_enable debug)
		--disable-nautilus
		--disable-python"
		# $(use_enable nautilus)
		# $(use_enable python)"
}

src_prepare() {
	gnome2_src_prepare

	# Fix broken smclient option passing
	epatch "${FILESDIR}/${P}-smclient-target-detection.patch"

	epatch "${FILESDIR}"/${P}-remove-libunique-dep.patch
	epatch "${FILESDIR}"/${P}-gapplication-fix.patch

	# not yet upstream
	epatch "${FILESDIR}/${PN}-2.90.0-gtk-api-changes.patch"

	intltoolize --force --copy --automake || die "intltoolize failed"
	eautoreconf

	# disable pyc compiling
	mv py-compile py-compile.orig
	ln -s $(type -P true) py-compile
}

src_configure() {
	# FIXME: why does it need write access here, probably need to set up a fake
	# home in /var/tmp like other pkgs do

	addpredict "$(unset HOME; echo ~)/.gconf"
	addpredict "$(unset HOME; echo ~)/.gconfd"
	addpredict "$(unset HOME; echo ~)/.gnome2"

	gnome2_src_configure
}

src_install() {
	gnome2_src_install
	# Installed for plugins, but they're dlopen()-ed
	# firefox, totem as well as nautilus
	find "${D}" -name "*.la" -delete || die "remove of la files failed"
}

pkg_postinst() {
	gnome2_pkg_postinst
#	if use python; then
#		python_need_rebuild
#		python_mod_optimize /usr/$(get_libdir)/totem/plugins
#	fi

	ewarn
	ewarn "If totem doesn't play some video format, please check your"
	ewarn "USE flags on media-plugins/gst-plugins-meta"
	ewarn
}

pkg_postrm() {
	gnome2_pkg_postrm
#	python_mod_cleanup /usr/$(get_libdir)/totem/plugins
}
