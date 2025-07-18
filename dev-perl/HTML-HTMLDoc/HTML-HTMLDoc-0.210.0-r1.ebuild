# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DIST_AUTHOR=ECHERNOF
DIST_VERSION=0.21
inherit perl-module

DESCRIPTION="Perl interface to the htmldoc program for producing PDF-Files from HTML-Content"

SLOT="0"
KEYWORDS="amd64 ~arm ~ppc sparc x86"

RDEPEND="app-text/htmldoc
	>=dev-perl/Devel-CheckBin-0.40.0
"
BDEPEND="${RDEPEND}
	>=dev-perl/Module-Build-Tiny-0.35.0
	test? ( >=virtual/perl-Test-Simple-0.980.0 )
"
