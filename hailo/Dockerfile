FROM idein/actcast-rpi-app-base:buster-2 as builder

RUN apt update

RUN apt install build-essential -y
RUN apt install git -y
RUN git clone https://github.com/hailo-ai/hailort.git -b v4.14.0

RUN apt install cmake -y
RUN apt install python3 -y
RUN apt install python3-distutils -y
RUN mkdir /root/hailort/build
WORKDIR /root/hailort/build
RUN cmake -DCMAKE_BUILD_TYPE=Release ..
RUN make -j 3
RUN make install DESTDIR=/artifacts

FROM idein/actcast-rpi-app-base:buster-2

COPY --from=builder /artifacts /

RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y libatomic1 \
 && apt-get clean \
 && apt-get autoclean \
 && apt-get autoremove -y \
 && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*
