# Actcast Raspberry Pi アプリベースイメージ

## Build

dockerをインストールしてmultiarch対応させた上で，

```console
$ make
```

すると，`idein/actcast-rpi-app-base` イメージが作成される．

```console
$ docker images idein/actcast-rpi-app-base
REPOSITORY                   TAG        IMAGE ID       CREATED          SIZE
idein/actcast-rpi-app-base   latest     4413af65372d   57 minutes ago   87.5MB
```

## Upgrade

Raspberry Pi OS のアップグレードに応じて新たなバージョンのベースイメージを作成する場合，
リポジトリ内のバージョンコードネーム(stretch, buster, bullseye等)を新しいコードネームに置換する．

```console
$ git grep bullseye
.circleci/config.yml:            if [ "${CIRCLE_TAG}" = "bullseye" ]
Dockerfile.builder:FROM debian:bullseye
builder:readonly RASPBIAN_VERSION=${RAPBIAN_VERSION:-bullseye}
```

## Release

バージョンコードネームのタグを打ってpushするとCircleCI上でイメージがビルドされ，
`idein/actcast-rpi-app-base:[codename]` としてhubにアップロードされる．

```
$ git tag bullseye
$ git push origin bullseye
(wait...)
$ docker pull idein/actcast-rpi-app-base:bullseye
```

## Patch Release

同バージョンコードネームでもベースイメージにパッチを当てて(≒何らかの変更をして)リリースする必要が生じた場合，
名前を [codename]-1, [codename]-2, … としてリリースする．

## actdkが作成するアプリベースイメージの変更

[`RPI_BASE_IMAGE_NAME`](https://github.com/Idein/actdk-package/blob/bc2b38c9ee6e46a95e86637cfb05894878bd7666/actdk/src/target_type.rs#L5)を差し替える．
