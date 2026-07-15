# Maintainer: minortex

pkgname=mechrevo-wujie14xa-ssdt-patch-git
_pkgname=mechrevo-wujie14xa-ssdt-patch
pkgver=r4.g598fab4
pkgrel=1
pkgdesc='ACPI SSDT overrides for Mechrevo Wujie 14x battery cycle count and temperature'
arch=('any')
url='https://github.com/minortex/mechrevo-wujie14xa-ssdt-patch'
license=('custom')
depends=('mkinitcpio')
makedepends=('git' 'acpica')
install="${pkgname}.install"
provides=("${_pkgname}")
conflicts=("${_pkgname}")
backup=('etc/mkinitcpio.conf.d/mechrevo-wujie14xa-ssdt-patch.conf')
source=("git+ssh://git@github.com/minortex/${_pkgname}.git")
sha256sums=('SKIP')

pkgver() {
  cd "${srcdir}/${_pkgname}"
  printf 'r%s.g%s' "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

build() {
  cd "${srcdir}/${_pkgname}"
  make
}

package() {
  cd "${srcdir}/${_pkgname}"

  install -Dm644 aml/ssdt-bix.aml "${pkgdir}/usr/lib/initcpio/acpi_override/ssdt-bix.aml"
  install -Dm644 /dev/stdin "${pkgdir}/etc/mkinitcpio.conf.d/mechrevo-wujie14xa-ssdt-patch.conf" <<'EOF'
# Include the packaged Mechrevo Wujie 14x ACPI table overrides in the early initramfs.
if [[ ${HOOKS@a} == *a* ]]; then
	case " ${HOOKS[*]} " in
		*" acpi_override "*) ;;
		*) HOOKS+=(acpi_override) ;;
	esac
else
	case " ${HOOKS} " in
		*" acpi_override "*) ;;
		*) HOOKS="${HOOKS} acpi_override" ;;
	esac
fi
EOF
}
