FIRMWARE_TYPE = bullseye

.PHONY: all
all: actcast-rpi-app-base-$(FIRMWARE_TYPE)

.PHONY: dist
dist: dist/actcast-rpi-app-base-$(FIRMWARE_TYPE).tar.gz

actcast-rpi-app-builder: Dockerfile.builder builder
	docker build -f $< -t idein/$@ .
	touch $@

rootfs_$(FIRMWARE_TYPE).tar.xz: actcast-rpi-app-builder
	-docker stop actcast-rpi-app-builder
	@sleep 5
	docker run -d --rm -it --privileged --name=actcast-rpi-app-builder -e RASPBIAN_VERSION=$(FIRMWARE_TYPE) idein/actcast-rpi-app-builder /bin/bash
	docker exec actcast-rpi-app-builder ./builder
	docker cp actcast-rpi-app-builder:/root/rootfs.tar.xz $@
	-docker stop actcast-rpi-app-builder

actcast-rpi-app-base-bullseye: Dockerfile.base rootfs_$(FIRMWARE_TYPE).tar.xz
	cp rootfs_$(FIRMWARE_TYPE).tar.xz rootfs.tar.xz
	docker build --platform=linux/arm/v7 -f $< -t idein/$@ .
	touch $@

actcast-rpi-app-base-bookworm: Dockerfile.bookworm
	docker buildx build --platform=linux/arm64 -f $< -t idein/$@ --load .
	touch $@

dist/actcast-rpi-app-base-$(FIRMWARE_TYPE).tar.gz: dist/%.tar.gz: %
	mkdir -p $(dir $@)
	docker save idein/$< | gzip > $@

.PHONY: clean
clean: clean-actcast-rpi-app-builder clean-actcast-rpi-app-base-$(FIRMWARE_TYPE)
	-$(RM) rootfs.tar.xz
	-$(RM) -r dist

.PHONY: clean-actcast-rpi-app-builder
clean-actcast-rpi-app-builder:
	-$(RM) actcast-rpi-app-builder
	-docker rmi idein/actcast-rpi-app-builder

.PHONY: clean-actcast-rpi-app-base-$(FIEMWARE_TYPE)
clean-actcast-rpi-app-base-$(FIRMWARE_TYPE):
	-$(RM) actcast-rpi-app-base-$(FIRMWARE_TYPE)
	-docker rmi idein/actcast-rpi-app-base-$(FIRMWARE_TYPE)


