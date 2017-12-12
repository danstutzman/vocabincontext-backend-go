FROM gliderlabs/alpine:3.3
MAINTAINER Bruno Celeste <bruno@coconut.co>

ENV FFMPEG_VERSION=3.0.2

WORKDIR /tmp/ffmpeg

RUN apk add --update build-base curl nasm tar bzip2 \
  zlib-dev openssl-dev yasm-dev lame-dev libogg-dev x264-dev libvpx-dev libvorbis-dev x265-dev freetype-dev libass-dev libwebp-dev rtmpdump-dev libtheora-dev opus-dev && \

  DIR=$(mktemp -d) && cd ${DIR} && \

  curl -s http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz | tar zxvf - -C . && \
  cd ffmpeg-${FFMPEG_VERSION} && \
  ./configure \
  --enable-version3 --enable-gpl --enable-nonfree --enable-small --enable-libmp3lame --enable-libx264 --enable-libx265 --enable-libvpx --enable-libtheora --enable-libvorbis --enable-libopus --enable-libass --enable-libwebp --enable-librtmp --enable-postproc --enable-avresample --enable-libfreetype --enable-openssl --disable-debug && \
  make && \
  make install && \
  make distclean && \

  rm -rf ${DIR} && \
  apk del build-base tar bzip2 x264 openssl nasm && rm -rf /var/cache/apk/*

RUN apk add --no-cache python gnupg \
  # Install youtube-dl
  # https://github.com/rg3/youtube-dl
&& curl -Lo /usr/local/bin/youtube-dl https://yt-dl.org/downloads/latest/youtube-dl \
&& curl -Lo youtube-dl.sig https://yt-dl.org/downloads/latest/youtube-dl.sig \
&& gpg --keyserver keyserver.ubuntu.com --recv-keys '7D33D762FD6C35130481347FDB4B54CBA4826A18' \
&& gpg --keyserver keyserver.ubuntu.com --recv-keys 'ED7F5BF46B3BBED81C87368E2C393E0F18A9236D' \
&& gpg --verify youtube-dl.sig /usr/local/bin/youtube-dl \
&& chmod a+rx /usr/local/bin/youtube-dl \
# Clean-up
&& rm youtube-dl.sig \
&& apk del curl gnupg \
# Create directory to hold downloads.
&& mkdir /downloads \
&& chmod a+rw /downloads \
# Basic check it works.
&& youtube-dl --version

COPY ./vocabincontext-backend-go /usr/local/bin/vocabincontext-backend-go

ENTRYPOINT ["/usr/local/bin/vocabincontext-backend-go"]
