# Actcast Raspberry Pi アプリベースイメージ

Actcast アプリケーションとして作成されるDockerイメージを作成する上で, ベースとなるイメージを提供します。

## 種類

`idein/actcast-rpi-app-base`
: RaspberryPi用アプリ作成のための最低限の設定をしたイメージ

`idein/actcast-rpi-app-base-python`
: RaspberryPi用アプリ作成に必要な最低限の環境にpythonとnumpyとpillowを追加したイメージ

## Build

dockerをインストールしてmultiarch対応させた上で，

```console
$ make
```

すると，`idein/actcast-rpi-app-base` イメージと `idein/actcast-rpi-app-base-python` イメージが作成される．

```console
$ docker images
REPOSITORY                          TAG        IMAGE ID       CREATED          SIZE
idein/actcast-rpi-app-base          latest     4413af65372d   57 minutes ago   87.5MB
idein/actcast-rpi-app-base-python   latest     b5cd2eca6a3a   19 minutes ago   189MB
```


## Upgrade

Raspberry Pi OS のアップグレードに応じて新たなバージョンのベースイメージを作成する場合，
リポジトリ内のバージョンコードネーム(stretch, buster等)を新しいコードネームに置換する．

```console
$ git grep [codename]
Dockerfile.builder:FROM debian:[codename]
builder:readonly RASPBIAN_VERSION=${RAPBIAN_VERSION:-[codename]}
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

バージョンコードネームに `-python` というサフィックスが付いている場合は，
`idein/actcast-rpi-app-base-python:[codename]` がhubにアップロードされる．

```console
$ git tag [codename]-python
$ git push origin [codename]-python
(wait...)
$ docker pull idein/actcast-rpi-app-base-python:[codename]
```

## Patch Release

同バージョンコードネームでもベースイメージにパッチを当てて(≒何らかの変更をして)リリースする必要が生じた場合，
tag名を [codename]-1, [codename]-2, … としてリリースする．
actcast-rpi-app-base-python にパッチを当てる場合は [codename]-python-1, [codename]-python-2, … とする．


## actdkが作成するアプリベースイメージの変更

[`RPI_BASE_IMAGE_NAME`](https://github.com/Idein/actdk-package/blob/bc2b38c9ee6e46a95e86637cfb05894878bd7666/actdk/src/target_type.rs#L5)を差し替える．
