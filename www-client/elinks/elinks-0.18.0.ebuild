# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

GUILE_REQ_USE="deprecated"
GUILE_COMPAT=( 2-2 3-0 )
PYTHON_COMPAT=( python3_{10..13} )
LUA_COMPAT=( lua5-{1,2,3,4} luajit )

inherit flag-o-matic guile-single meson lua-single python-single-r1

DESCRIPTION="Advanced and well-established text-mode web browser"
HOMEPAGE="http://elinks.or.cz/"

if [[ ${PV} == *9999 ]] ; then
	EGIT_REPO_URI="https://github.com/rkd77/felinks"
	inherit git-r3
else
	SRC_URI="https://github.com/rkd77/elinks/releases/download/v${PV}/${P}.tar.xz"

	KEYWORDS="~alpha amd64 arm ~arm64 ~hppa ~mips ppc ppc64 ~riscv sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x64-solaris"
fi

LICENSE="GPL-2"
SLOT="0"
IUSE="bittorrent brotli bzip2 curl debug +doc finger ftp gemini gopher gpm gnutls guile idn"
IUSE+=" javascript libcss lua lzma +mouse nls nntp perl python samba sftp ssl test tre unicode X xml zlib zstd"
RESTRICT="!test? ( test )"
REQUIRED_USE="
	guile? ( ${GUILE_REQUIRED_USE} )
	javascript? ( curl libcss )
	lua? ( ${LUA_REQUIRED_USE} )
	python? ( ${PYTHON_REQUIRED_USE} )
	sftp? ( curl )
"

RDEPEND="
	>=sys-libs/ncurses-5.2:=[unicode(+)]
	brotli? ( app-arch/brotli:= )
	bzip2? ( >=app-arch/bzip2-1.0.2 )
	curl? ( net-misc/curl[ssl] )
	gpm? (
		>=sys-libs/gpm-1.20.0-r5
	)
	guile? ( ${GUILE_DEPS} )
	idn? ( net-dns/libidn2:= )
	javascript? (
		dev-cpp/libxmlpp:5.0
		dev-lang/mujs:=
	)
	libcss? (
		>=dev-libs/libcss-0.9.2
		>=net-libs/libdom-0.4.2
	)
	lua? ( ${LUA_DEPS} )
	lzma? ( app-arch/xz-utils )
	perl? ( dev-lang/perl:= )
	python? ( ${PYTHON_DEPS} )
	samba? ( net-fs/samba )
	ssl? (
		!gnutls? ( dev-libs/openssl:= )
		gnutls? ( net-libs/gnutls:= )
	)
	tre? ( dev-libs/tre )
	X? (
		x11-libs/libX11
		x11-libs/libXt
	)
	xml? ( >=dev-libs/expat-1.95.4 )
	zlib? ( >=sys-libs/zlib-1.1.4 )
	zstd? ( app-arch/zstd:= )
"
DEPEND="${RDEPEND}
	X? ( x11-base/xorg-proto )"
BDEPEND="
	virtual/pkgconfig
	doc? ( dev-lang/perl )
	nls? ( sys-devel/gettext )
	test? (
		net-dns/libidn
	)
"

PATCHES=(
	"${FILESDIR}"/${P}-sftp.patch
	"${FILESDIR}"/${P}-build.patch
)

pkg_setup() {
	use guile && guile-single_pkg_setup
	use lua && lua-single_pkg_setup
	python-single-r1_pkg_setup
}

src_prepare() {
	default
	use guile && guile_bump_sources
	python_fix_shebang .
}

src_configure() {
	# This file is severely broken w.r.t. strict-aliasing and upstream acknowledges it:
	# https://github.com/rkd77/elinks/blob/d05ce90b35d82109aab320b490e3ca54aa6df057/src/util/lists.h#L14
	# https://github.com/rkd77/elinks/blob/d05ce90b35d82109aab320b490e3ca54aa6df057/src/meson.build#L44
	#
	# Although they force fno-strict-aliasing, they do so inconsistently and not for the testsuite (!!!).
	# Just add it again.
	#
	# DO not trust the LTO either.
	append-flags -fno-strict-aliasing
	filter-lto

	local emesonargs=(
		-Ddocdir="${EPREFIX}"/usr/share/doc/${PF}
		-Dhtmldoc=false
		-Dpdfdoc=false
		-Dapidoc=false
		-D88-colors=true
		-D256-colors=true
		-Dbacktrace=$(usex elibc_musl false true)
		$(meson_use bittorrent)
		$(meson_use brotli)
		$(meson_use bzip2 bzlib)
		$(meson_use curl libcurl)
		$(usex debug '-Ddebug=true' '-Dfastmem=true')
		$(meson_use doc)
		$(meson_use finger)
		$(meson_use ftp)
		-Dfsp=false
		$(meson_use gemini)
		$(meson_use nls gettext)
		$(meson_use gopher)
		$(meson_use gpm)
		$(meson_use guile)
		-Dgssapi=false
		-Dhtml-highlight=true
		$(meson_use idn)
		$(meson_use javascript mujs)
		-Dipv6=true
		-Dleds=true
		$(meson_use libcss)
		-Dlibev=false
		-Dlibevent=false
		-Dluapkg=$(usex lua ${ELUA:-0} '')
		$(meson_use lzma)
		$(meson_use mouse)
		$(meson_use nls)
		$(meson_use nntp)
		$(meson_use perl)
		$(meson_use python)
		-Dquickjs=false
		-Druby=false
		$(meson_use samba smb)
		$(meson_use sftp)
		-Dsm-scripting=false
		-Dspidermonkey=false
		-Dterminfo=true
		$(meson_use test)
		$(meson_use tre)
		-Dtrue-color=true
		$(meson_use xml xbel)
		$(meson_use X x)
		$(meson_use zlib)
		$(meson_use zstd)
	)

	if use ssl ; then
		if use gnutls ; then
			emesonargs+=( -Dgnutls=true )
		else
			emesonargs+=( -Dopenssl=true)
		fi
	else
		emesonargs+=( -Dgnutls=false -Dopenssl=false )
	fi

	meson_src_configure
}

src_install() {
	meson_src_install

	insinto /etc/elinks
	newins contrib/keybind-full.conf keybind-full.sample
	newins contrib/keybind.conf keybind.conf.sample

	dodoc AUTHORS BUGS ChangeLog INSTALL NEWS README.md SITES THANKS TODO doc/*.*
	docinto contrib ; dodoc contrib/{README,colws.diff,elinks[-.]vim*}
	docinto contrib/lua ; dodoc contrib/lua/{*.lua,elinks-remote}
	docinto contrib/conv ; dodoc contrib/conv/*.*
	docinto contrib/guile ; dodoc contrib/guile/*.scm

	# elinks uses an internal copy of gettext which ships files that may
	# collide with the system's gettext (https://bugs.gentoo.org/635090)
	rm -f "${ED}"/usr/{share/locale/locale,lib/charset}.alias || die

	use guile && guile_unstrip_ccache
}

pkg_postinst() {
	elog "If upgrading from a version prior to 0.17.0, you will need to move"
	elog "your configuration from ~/.elinks to \${XDG_CONFIG_HOME}/elinks"
	elog
	elog "You may want to convert your html.cfg and links.cfg of"
	elog "Links or older ELinks versions to the new ELinks elinks.conf"
	elog "using ${EROOT}/usr/share/doc/${PF}/contrib/conv/conf-links2elinks.pl"
	elog
	elog "Please have a look at ${EROOT}/etc/elinks/keybind-full.sample and"
	elog "${EROOT}/etc/elinks/keybind.conf.sample for some bindings examples."
	elog
	elog "You will have to set your TERM variable to 'xterm-256color'"
	elog "to be able to use 256 colors in elinks."
}
