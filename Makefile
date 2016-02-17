CHROOT_DIR := `dirname $(NETMOON_CHROOT)/bin`
CUR_DIR := `pwd`
USER := `whoami`
USER_ID := `whoami | xargs id -u`

all:
	$(compile_target_in_chroot)
%::
	$(compile_target_in_chroot)
apps/*/* modules/*/* libs/*/* libs modules apps romfs::
	$(compile_target_in_chroot)
update::
	@make -f Makefile.real $@ >/dev/null
help::
	@make -f Makefile.real $@

chroot-init::
	@if ! test -f $(CHROOT_DIR)/etc/passwd > /dev/null; then \
		sudo $(CHROOT_DIR)/init.sh; \
	fi
	@if ! grep "$(USER)" $(CHROOT_DIR)/etc/passwd > /dev/null; then \
		sudo chroot $(CHROOT_DIR) /bin/bash -c "useradd $(USER) -u $(USER_ID)"; \
	fi

chroot-mount::
	@if ! mount | egrep "$(CHROOT_DIR)/proc " > /dev/null; then \
		sudo mount /proc/ -t proc $(CHROOT_DIR)/proc; \
	fi
	@if ! mount | egrep "$(CHROOT_DIR)/tmp " > /dev/null; then \
		sudo mount -t tmpfs tmpfs $(CHROOT_DIR)/tmp; \
		sudo chmod 777 $(CHROOT_DIR)/tmp -R; \
	fi
	@if ! mount | egrep "$(CHROOT_DIR)/home " > /dev/null; then \
		test -d $(CHROOT_DIR)/home/$(USER) || sudo mkdir $(CHROOT_DIR)/home/$(USER) -p; \
		sudo mount -t tmpfs tmpfs $(CHROOT_DIR)/home; \
	fi
	@if ! mount | egrep "$(CHROOT_DIR)$(CUR_DIR) " > /dev/null; then \
		test -d $(CHROOT_DIR)$(CUR_DIR) || sudo mkdir $(CHROOT_DIR)$(CUR_DIR) -p; \
		sudo mount $(CUR_DIR) $(CHROOT_DIR)$(CUR_DIR) -R; \
	fi

# You should only umount the product dir, otherwise it will break other products compile.
chroot-umount::
	@-if mount | egrep "$(CHROOT_DIR)$(CUR_DIR) " > /dev/null; then \
		sudo umount $(CHROOT_DIR)$(CUR_DIR) >/dev/null 2>&1; \
		echo "" > /dev/null; \
	fi

define	compile_target_in_chroot
	@if [ "root" == $(USER) ]; then \
		echo "You can not run as root user"; \
		exit 1; \
	fi
	@make chroot-init > /dev/null
	@make chroot-mount > /dev/null
	@if mount | egrep "$(CHROOT_DIR)$(CUR_DIR) " > /dev/null; then \
		sudo chroot --userspec=$(USER) $(CHROOT_DIR) /bin/bash -c "cd $(CUR_DIR);make -f Makefile.real $@ version=$(version)" || (make chroot-umount;exit 1;) \
	fi
	@make chroot-umount
endef
