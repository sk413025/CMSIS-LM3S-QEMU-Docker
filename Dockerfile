# CMSIS_LM3S QEMU ARM 執行環境
# 基於 Debian，預裝 QEMU ARM 系統模擬器

FROM debian:bookworm-slim

LABEL maintainer="CMSIS_LM3S Project"
LABEL description="QEMU ARM emulator for LM3S Cortex-M3 development"
LABEL version="1.0"

# 更新套件列表並安裝 QEMU ARM
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        qemu-system-arm \
        ca-certificates && \
    # 清理 apt 快取以減少映像大小
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 設定工作目錄
WORKDIR /work

# 預設指令：顯示 QEMU 版本
CMD ["qemu-system-arm", "--version"]
