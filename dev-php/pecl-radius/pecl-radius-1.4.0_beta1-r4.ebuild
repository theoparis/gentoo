# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"

PHP_EXT_NAME="radius"
PHP_EXT_INI="yes"
PHP_EXT_ZENDEXT="no"

USE_PHP="php8-2 php8-3"
PHP_EXT_PECL_FILENAME="${PN/pecl-/}-${PV/_beta/b}.tgz"
PHP_EXT_S="${WORKDIR}/${PHP_EXT_PECL_FILENAME%.tgz}"
PHP_EXT_NEEDED_USE="pcntl(-),sockets(-)"

inherit php-ext-pecl-r3

DESCRIPTION="Provides support for RADIUS authentication (RFC 2865) and accounting (RFC 2866)"
HOMEPAGE="https://pecl.php.net/package/radius"
S="${PHP_EXT_S}"
LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="examples"

PATCHES=( "${FILESDIR}/1.4.0-php8.patch" )

src_unpack() {
	default
	# Non-portable test
	rm "${S}/tests/radius_close.phpt" || die
}
