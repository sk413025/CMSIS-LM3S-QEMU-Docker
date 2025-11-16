# CMSIS_LM3S GDB 除錯環境
# 基於 Debian，包含 QEMU ARM 和 GDB Multi-Arch

FROM debian:bookworm-slim

LABEL maintainer="CMSIS_LM3S Project"
LABEL description="QEMU ARM + GDB for LM3S Cortex-M3 debugging"
LABEL version="1.0"

# 安裝 QEMU 和 GDB
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        qemu-system-arm \
        gdb-multiarch \
        ca-certificates \
        netcat-openbsd && \
    # 清理 apt 快取
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 設定工作目錄
WORKDIR /work

# 預設指令：啟動 bash
CMD ["bash"]
