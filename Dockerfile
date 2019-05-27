FROM lambci/lambda-base:build

RUN yum update -y

RUN yum install -y install autoconf \
  automake \
  bzip2 \
  bzip2-devel \
  cmake \
  freetype-devel \
  gcc \
  gcc-c++ \
  git \
  libtool \
  make \
  mercurial \
  pkgconfig \
  zlib-devel \
  libfdk-aac-dev

RUN mkdir ~/ffmpeg_sources

# Install Nasm
# An assembler used by some libraries. Highly recommended or your resulting build may be very slow.
RUN cd ~/ffmpeg_sources && \
  curl -O -L https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.bz2 && \
  tar xjvf nasm-2.14.02.tar.bz2 && \
  cd nasm-2.14.02 && \
  ./autogen.sh && \
  ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" && \
  PATH="$HOME/bin:$PATH" make && \
  make install

# Install Yasm
# An assembler used by some libraries. Highly recommended or your resulting build may be very slow.
RUN cd ~/ffmpeg_sources && \
  curl -O -L https://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz && \
  tar xzvf yasm-1.3.0.tar.gz && \
  cd yasm-1.3.0 && \
  ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" && \
  make && \
  make install

# Install libx264
# H.264 video encoder. 
RUN cd ~/ffmpeg_sources && \
  git clone --depth 1 https://code.videolan.org/videolan/x264.git && \
  cd x264 && \
  PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static && \
  PATH="$HOME/bin:$PATH" make && \
  make install

# Install libx265
# H.265/HEVC video encoder.
RUN cd ~/ffmpeg_sources && \
  hg clone https://bitbucket.org/multicoreware/x265 && \
  cd ~/ffmpeg_sources/x265/build/linux && \
  PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source && \
  make && \
  make install

# Install libfdk_aac
# AAC audio encoder. 
RUN cd ~/ffmpeg_sources  && \
  git clone --depth 1 https://github.com/mstorsjo/fdk-aac && \
  cd fdk-aac && \
  autoreconf -fiv && \
  PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --disable-shared && \
  PATH="$HOME/bin:$PATH" make && \
  make install

# Install libmp3lame
# MP3 audio encoder.
RUN cd ~/ffmpeg_sources && \
  curl -O -L https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz && \
  tar xzvf lame-3.100.tar.gz && \
  cd lame-3.100 && \
  PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --disable-shared --enable-nasm && \
  PATH="$HOME/bin:$PATH" make && \
  make install

# Install libopus
# Opus audio decoder and encoder
RUN cd ~/ffmpeg_sources && \
  curl -O -L https://archive.mozilla.org/pub/opus/opus-1.3.1.tar.gz && \
  tar xzvf opus-1.3.1.tar.gz && \
  cd opus-1.3.1 && \
  PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --disable-shared && \
  PATH="$HOME/bin:$PATH" make && \
  make install

# Install libvpx
# VP8/VP9 video encoder and decoder.
RUN cd ~/ffmpeg_sources && \
  git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git && \
  cd libvpx && \
  PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm && \
  PATH="$HOME/bin:$PATH" make && \
  make install

ARG FFMPEG_VERSION

# Install ffmpeg
RUN cd ~/ffmpeg_sources && \
  curl -O -L https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && \
  tar xjvf ffmpeg-snapshot.tar.bz2 && \
  cd ffmpeg && \
  PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
    --prefix="$HOME/ffmpeg_build" \
    --pkg-config-flags="--static" \
    --extra-cflags="-I$HOME/ffmpeg_build/include" \
    --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
    --extra-libs=-lpthread \
    --extra-libs=-lm \
    --bindir="$HOME/bin" \
    --enable-gpl \
    --enable-libfdk_aac \
    --enable-libfreetype \
    --enable-libmp3lame \
    --enable-libopus \
    --enable-libvpx \
    --enable-libx264 \
    --enable-libx265 \
    --enable-nonfree && \
  make && \
  make install && \
  hash -d ffmpeg

RUN cd $HOME/bin && \
  find . ! -perm -o=r -exec chmod +400 {} \; && \
  zip -yr /tmp/ffmpeg-${FFMPEG_VERSION}.zip ./*
