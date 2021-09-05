#!/bin/bash

cat << EOF

Create base image using "gcr.io/distroless/base:XXXXXXXX"
holding only the required libraries to run the target appplication

EOF
#NOTE: nonroot userID is 65532
BASE_IMAGE="gcr.io/distroless/base"
SHA256="sha256:a74f307185001c69bc362a40dbab7b67d410a872678132b187774fa21718fa13"
DEB_ARCH="amd64.deb"
DIR=lib
TAG=tor-base-image:x86_64

mkdir $DIR
cd $DIR

for LIB in $(cat ../ldd)
do
  wget --quiet $LIB$DEB_ARCH
done

CONTAINER=$(buildah from --quiet $BASE_IMAGE@$SHA256)

for x in $(ls -1 .)
do
  ar x $x data.tar.xz
  buildah add $CONTAINER data.tar.xz /
done

cd .. && rm -r $PWD/$DIR
ID=$(buildah list --quiet --filter name=$CONTAINER)
IMAGE=$(buildah commit --timestamp 0 $ID $TAG)
buildah rm $ID 1>/dev/null
cat << EOF

Image: $TAG
Digest: $IMAGE

Done!
EOF
