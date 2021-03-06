all: actcast-rpi-app-base

dist: actcast-rpi-app-base.tar.gz

actcast-rpi-app-builder: Dockerfile.builder
	docker build -f $< -t idein/$@ .
	touch $@

rootfs.tar.xz: actcast-rpi-app-builder
	-docker stop actcast-rpi-app-builder
	@sleep 5
	docker run -d --rm -it --privileged --name=actcast-rpi-app-builder idein/actcast-rpi-app-builder /bin/bash
	docker exec actcast-rpi-app-builder ./builder
	docker cp actcast-rpi-app-builder:/root/rootfs.tar.xz .
	-docker stop actcast-rpi-app-builder

actcast-rpi-app-base: Dockerfile.base rootfs.tar.xz
	docker build -f $< -t idein/$@ .
	touch $@

actcast-rpi-app-base.tar.gz: actcast-rpi-app-base
	docker save idein/$< | gzip > $@

clean: clean-actcast-rpi-app-builder clean-actcast-rpi-app-base
	-rm rootfs.tar.xz
	-rm actcast-rpi-app-base.tar.gz

clean-actcast-rpi-app-builder:
	-rm actcast-rpi-app-builder
	-docker rmi idein/actcast-rpi-app-builder

clean-actcast-rpi-app-base:
	-rm actcast-rpi-app-base
	-docker rmi idein/actcast-rpi-app-base
