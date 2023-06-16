all: actcast-rpi-app-base-python

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

actcast-rpi-app-base-python: Dockerfile.python actcast-rpi-app-base
	docker build -f $< -t idein/$@ .
	touch $@

actcast-rpi-app-base: Dockerfile.base rootfs.tar.xz
	docker build -f $< -t idein/$@ .
	touch $@

dist/actcast-rpi-app-base.tar.gz dist/actcast-rpi-app-base-python.tar.gz: dist/%.tar.gz: %
	mkdir -p $(dir $@)
	docker save idein/$< | gzip > $@

clean: clean-actcast-rpi-app-builder clean-actcast-rpi-app-base
	-rm rootfs.tar.xz
	-rm -rf dist

clean-actcast-rpi-app-builder:
	-rm actcast-rpi-app-builder
	-docker rmi idein/actcast-rpi-app-builder

clean-actcast-rpi-app-base:
	-rm actcast-rpi-app-base
	-docker rmi idein/actcast-rpi-app-base
