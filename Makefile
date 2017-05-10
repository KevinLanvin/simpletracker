include $(TOPDIR)/rules.mk

PKG_NAME:=tracker
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_MAINTAINER:=Kevin Lanvin <kevin.lanvin@corp.ovh.com>
PKG_LICENSE:=MIT

include $(INCLUDE_DIR)/package.mk
$(call include_mk, python-package.mk)

define Package/$(PKG_NAME)
  SUBMENU:=Python
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=OTB tracker
  DEPENDS:=+python-light +python-logging
endef

define Package/$(PKG_NAME)/description
	A python module to track OTB connections
endef

define Build/Prepare
	$(CP) ./files/* $(PKG_BUILD_DIR)
endef

define Build/Compile
	$(call Build/Compile/PyMod,, \
		install --no-compile --prefix="/usr" --root=$(PKG_INSTALL_DIR), \
	)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)$(PYTHON_PKG_DIR)
	$(CP) $(PKG_INSTALL_DIR)$(PYTHON_PKG_DIR)/* $(1)$(PYTHON_PKG_DIR)

	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/simpletracker.py $(1)/usr/bin/tracker
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
