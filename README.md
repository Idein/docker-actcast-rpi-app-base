# Actcast Raspberry Pi アプリベースイメージ

Actcast アプリケーションとして作成されるDockerイメージを作成する上で, ベースとなるイメージを提供します。

## 種類

`idein/actcast-rpi-app-base`
: RaspberryPi用アプリ作成のための最低限の設定をしたイメージ

## Build

dockerをインストールしてmultiarch対応させた上で，

```console
$ make
```

すると，`idein/actcast-rpi-app-base-bullseye` イメージが作成される．

```console
$ docker images
REPOSITORY                          TAG        IMAGE ID       CREATED          SIZE
idein/actcast-rpi-app-base-bullseye latest     4413af65372d   57 minutes ago   87.5MB
```

buster版をビルドしたい場合は、

```console
$ make FIRMWARE_TYPE=buster actcast-rpi-app-base-buster
```

とする。


## Upgrade

Raspberry Pi OS のアップグレードに応じて新たなバージョンのベースイメージを作成する場合，
リポジトリ内のバージョンコードネーム(stretch, buster等)を新しいコードネームに置換する．

```console
$ git grep [codename]
Dockerfile.builder:FROM debian:[codename]
builder:readonly RASPBIAN_VERSION=${RASPBIAN_VERSION:-[codename]}
```

## Release

バージョンコードネームのタグを打ってpushするとCircleCI上でイメージがビルドされ，
`idein/actcast-rpi-app-base:[codename]` がhubにアップロードされる．

```console
$ git tag [codename]
$ git push origin [codename]
(wait...)
$ docker pull idein/actcast-rpi-app-base:[codename]
```

## Patch Release

同バージョンコードネームでもベースイメージにパッチを当てて(≒何らかの変更をして)リリースする必要が生じた場合，
tag名を [codename]-1, [codename]-2, … としてリリースする．


## actdkが作成するアプリベースイメージの変更

[`RPI_BASE_IMAGE_NAME`](https://github.com/Idein/actdk-package/blob/bc2b38c9ee6e46a95e86637cfb05894878bd7666/actdk/src/target_type.rs#L5)を差し替える．
