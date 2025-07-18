# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit elisp

DESCRIPTION="Compatibility libraries for Emacs"
HOMEPAGE="https://github.com/emacs-compat/compat/
	https://git.sr.ht/~pkal/compat/"

if [[ "${PV}" == *9999* ]] ; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/emacs-compat/${PN}.git"
else
	SRC_URI="https://github.com/emacs-compat/${PN}/archive/${PV}.tar.gz
		-> ${P}.tar.gz"

	KEYWORDS="amd64 arm arm64 ppc64 ~riscv x86"
fi

LICENSE="GPL-3+"
SLOT="0"

BDEPEND="
	sys-apps/texinfo
"

ELISP_TEXINFO="${PN}.texi"

src_prepare() {
	elisp_src_prepare

	# Skip failing test.
	local -a skip_tests=(
		compat-read-answer
		compat-read-multiple-choice
	)
	local skip_test=""
	for skip_test in "${skip_tests[@]}"; do
		sed -i "/${skip_test}/a (ert-skip nil)" ./compat-tests.el || die
	done
}

src_test() {
	local has_json="$("${EMACS}" ${EMACSFLAGS} --eval "(princ (fboundp 'json-parse-string))")"
	if [[ "${has_json}" != t ]] ; then
		local line
		while read line ; do
			ewarn "${line}"
		done <<-EOF
		Your current Emacs version does not support native JSON parsing,
		which is required for running tests of ${CATEGORY}/${PN}.
		Emerge >=app-editors/emacs-27 with USE="json" and use "eselect emacs"
		to select that version.
		EOF
	else
		emake test
	fi
}

src_install() {
	rm ./compat-tests.el || die

	elisp_src_install
}
