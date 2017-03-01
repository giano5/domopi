VERSION=1.0.3
SIZE=
PACKAGE_NAME=domopi
BUILDROOT=/tmp
# Elencare con spazi e senza quotatura le cartelle da trasportare
ROOTS=usr
ARCH=all
DOMOPI_CONF_PATH=/usr/local/etc/domopi
DOMOPI_CONF_TEMPLATE_PATH=/usr/local/var/lib/domopi
DOMOPI_BIN_PATH=/usr/local/bin
DOMOPI_API_PATH=/usr/local/libexec


prebuild: build-src/DEBIAN/control build-src/DEBIAN/preinst build-src/DEBIAN/prerm\
	  build-src/DEBIAN/postinst build-src/DEBIAN/postrm\
	  src/domopi.functions src/test.sh src/domod.sh src/conf/modules.cfg\
	  src/conf/domopi

	@echo Reconfiguring...
	@mkdir -p ${BUILDROOT}/${PACKAGE_NAME}-${VERSION}/DEBIAN
	@mkdir -p ${BUILDROOT}/${PACKAGE_NAME}-${VERSION}/${DOMOPI_CONF_PATH}
	@mkdir -p ${BUILDROOT}/${PACKAGE_NAME}-${VERSION}/${DOMOPI_CONF_TEMPLATE_PATH}
	@mkdir -p ${BUILDROOT}/${PACKAGE_NAME}-${VERSION}/${DOMOPI_BIN_PATH}
	@mkdir -p ${BUILDROOT}/${PACKAGE_NAME}-${VERSION}/${DOMOPI_API_PATH}
	@mkdir -p ${BUILDROOT}/${PACKAGE_NAME}-${VERSION}/usr/local/etc/default

	@install --mode 755 build-src/DEBIAN/preinst ${BUILDROOT}/${PACKAGE_NAME}-${VERSION}/DEBIAN/
	@install --mode 755 build-src/DEBIAN/prerm ${BUILDROOT}/${PACKAGE_NAME}-${VERSION}/DEBIAN/
	@install --mode 755 build-src/DEBIAN/postinst ${BUILDROOT}/${PACKAGE_NAME}-${VERSION}/DEBIAN/
	@install --mode 755 build-src/DEBIAN/postrm ${BUILDROOT}/${PACKAGE_NAME}-${VERSION}/DEBIAN/
	@install --mode 555 src/domopi.functions ${BUILDROOT}/${PACKAGE_NAME}-${VERSION}/${DOMOPI_API_PATH}
	@install --mode 555 src/domod.sh ${BUILDROOT}/${PACKAGE_NAME}-${VERSION}/${DOMOPI_BIN_PATH}
	@install --mode 555 src/test.sh ${BUILDROOT}/${PACKAGE_NAME}-${VERSION}/${DOMOPI_BIN_PATH}/domopi-test.sh
	@install --mode 444 src/conf/modules.cfg ${BUILDROOT}/${PACKAGE_NAME}-${VERSION}/${DOMOPI_CONF_TEMPLATE_PATH}
	@install --mode 444 src/conf/domopi ${BUILDROOT}/${PACKAGE_NAME}-${VERSION}/usr/local/etc/default

	@cd ${BUILDROOT}/${PACKAGE_NAME}-${VERSION} ; find ${ROOTS} -type f -exec md5sum '{}' \; >${BUILDROOT}/${PACKAGE_NAME}-${VERSION}/DEBIAN/md5sums
#	@chmod 755 ${BUILDROOT}/${PACKAGE_NAME}-${VERSION}/DEBIAN/*

	@SIZE=`du -s ${BUILDROOT}/${PACKAGE_NAME}-${VERSION} | awk '{ print $$1 }'`; awk -vname=${PACKAGE_NAME} -vvers=${VERSION} -varch=${ARCH} -vsize=$$SIZE\
				    '/^Package:/{ print $$1" "name; next }\
				     /^Version:/{ print $$1" "vers; next }\
				     /^Installed-Size:/{ print $$1" "size; next }\
				     /^Architecture:/{ print $$1" "arch; next }\
					        { print $$0 }'\
			build-src/DEBIAN/control >${BUILDROOT}/${PACKAGE_NAME}-${VERSION}/DEBIAN/control


build: prebuild
	@echo Building...
	dpkg-deb -b ${BUILDROOT}/${PACKAGE_NAME}-${VERSION}
