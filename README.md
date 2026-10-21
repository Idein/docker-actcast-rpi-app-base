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

## eMudhra 中間CAの秘密鍵問題への対応 (2026-10)

`block-emudhra-ca.sh` は `emSign ECC Root CA - G3` と、クロス署名元の
`AAA Certificate Services` (`Comodo_AAA_Services_root.crt`) を
`/etc/ca-certificates.conf` で無効化し、CAバンドルと証明書リンクを再生成する。
bullseye、bookworm、およびbookwormから派生するGUIイメージに適用する。
ディストリビューションの更新状況に依存せず、同じ設定を適用する。
背景は [Mozillaのインシデント記録](https://bugzilla.mozilla.org/show_bug.cgi?id=2083449) を参照。

ビルド後、次のコマンドで無効化したルートの拒否と、Amazon Root CA 1の維持を検証する。
CAバンドルとOpenSSLの証明書ディレクトリをそれぞれ確認し、失敗時は公開しない。
CircleCIでも、通常イメージとGUIイメージの公開前に実行する。

```console
docker run --rm -v "$PWD/tests:/tests:ro" idein/actcast-rpi-app-base-bullseye sh /tests/check-ca-certificates.sh
docker run --rm -v "$PWD/tests:/tests:ro" idein/actcast-rpi-app-base-bookworm sh /tests/check-ca-certificates.sh
docker run --rm -v "$PWD/tests:/tests:ro" idein/actcast-rpi-app-base-gui-bookworm sh /tests/check-ca-certificates.sh
```

リリースには未使用の `bullseye-4` と `bookworm-10` を使う予定。
両タグのビルド・公開とテストの成功を確認してから、これらを参照するActDKをリリースする。
既存のActには自動反映されないため、新しいActDKでの再ビルドと再配信を案内する。
custom imageや独自のCAストアを使うアプリは個別の更新が必要。
Pythonのcertifiなど、OSとは別のCAストアはこのスクリプトの対象に含まれない。
