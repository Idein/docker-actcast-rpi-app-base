.PHONY: all
all: actcast-rpi-app-base-python actcast-rpi-app-base

.PHONY: dist
dist: dist/actcast-rpi-app-base.tar.gz dist/actcast-rpi-app-base-python.tar.gz

actcast-rpi-app-builder: Dockerfile.builder builder
	docker build -f $< -t idein/$@ .
	touch $@

rootfs.tar.xz: actcast-rpi-app-builder
	-docker stop actcast-rpi-app-builder
	@sleep 5
	docker run -d --rm -it --privileged --name=actcast-rpi-app-builder idein/actcast-rpi-app-builder /bin/bash
	docker exec actcast-rpi-app-builder ./builder
	docker cp actcast-rpi-app-builder:/root/rootfs.tar.xz .
	-docker stop actcast-rpi-app-builder

actcast-rpi-app-base-python: Dockerfile.python
	docker buildx build -f $< -t idein/$@ --load .
	touch $@

actcast-rpi-app-base: Dockerfile.base rootfs.tar.xz
	docker build -f $< -t idein/$@ .
	touch $@

dist/actcast-rpi-app-base.tar.gz dist/actcast-rpi-app-base-python.tar.gz: dist/%.tar.gz: %
	mkdir -p $(dir $@)
	docker save idein/$< | gzip > $@

.PHONY: clean
clean: clean-actcast-rpi-app-builder clean-actcast-rpi-app-base clean-actcast-rpi-app-base-python
	-$(RM) rootfs.tar.xz
	-$(RM) -r dist

.PHONY: clean-actcast-rpi-app-builder
clean-actcast-rpi-app-builder:
	-$(RM) actcast-rpi-app-builder
	-docker rmi idein/actcast-rpi-app-builder

.PHONY: clean-actcast-rpi-app-base
clean-actcast-rpi-app-base:
	-$(RM) actcast-rpi-app-base
	-docker rmi idein/actcast-rpi-app-base

.PHONY: clean-actcast-rpi-app-base-python
clean-actcast-rpi-app-base-python:
	-$(RM) actcast-rpi-app-base-python
	-docker rmi idein/actcast-rpi-app-base-python

