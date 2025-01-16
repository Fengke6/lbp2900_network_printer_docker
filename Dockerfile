# 第一阶段：构建阶段
FROM ubuntu:20.04 AS builder

# 设置非交互式前端
ARG DEBIAN_FRONTEND=noninteractive

# 安装构建依赖项
RUN apt update && apt install -y \
    build-essential \
    git \
    autoconf \
    libtool \
    cups \
    libcups2-dev \
    libcupsimage2-dev \
 && rm -rf /var/lib/apt/lists/*

# 克隆并构建 captdriver
RUN git clone https://github.com/agalakhov/captdriver.git /captdriver
WORKDIR /captdriver
RUN autoreconf -i \
 && ./configure \
 && make

# 第二阶段：运行阶段
FROM ubuntu:20.04-slim

# 设置非交互式前端
ARG DEBIAN_FRONTEND=noninteractive

# 安装运行依赖项
RUN apt update && apt install -y \
    cups \
    libcups2 \
    libcupsimage2 \
 && rm -rf /var/lib/apt/lists/*

# 从构建阶段复制构建结果
COPY --from=builder /captdriver/src/rastertocapt /usr/lib/cups/filter/
COPY --from=builder /captdriver/Canon*.ppd /usr/share/ppd/custom/

# 设置 root 密码
RUN echo 'root:Printer!' | chpasswd

# 复制配置文件
COPY cupsd.conf /etc/cups/cupsd.conf
COPY printers.conf /etc/cups/printers.conf
RUN cp /usr/share/ppd/custom/Canon-LBP2900.ppd /etc/cups/ppd/Canon_LBP2900_docker.ppd

# 启动 CUPS 服务并保持容器运行
ENTRYPOINT ["sh", "-c", "service cups start && bash"]
