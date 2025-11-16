# CMSIS_LM3S Docker 使用指南

## 快速開始

### 方法 1: 使用自動化腳本（推薦）

```bash
# 執行所有範例
./run-examples.sh all

# 只執行 UART 範例
./run-examples.sh uart

# 只執行 FIR 濾波器範例
./run-examples.sh fir

# 顯示幫助
./run-examples.sh help
```

### 方法 2: 使用 Docker 命令

**建置 Docker image（首次使用）：**
```bash
docker build -t cmsis-lm3s-qemu:latest .
```

**執行 UART Hello World：**
```bash
docker run --rm \
    -v $(pwd):/work:ro \
    -w /work/examples/uart_hello_world/gcc \
    cmsis-lm3s-qemu:latest \
    timeout 2 qemu-system-arm -M lm3s6965evb -nographic -kernel uart_hello_world.bin
```

**執行 FIR 濾波器：**
```bash
docker run --rm \
    -v $(pwd):/work:ro \
    -w /work/examples/arm_fir_example/gcc \
    cmsis-lm3s-qemu:latest \
    timeout 2 qemu-system-arm -M lm3s6965evb -nographic -kernel arm_fir_example_f32.bin
```

### 方法 3: 使用 Docker Compose

**執行 UART 範例：**
```bash
docker-compose run --rm uart-hello
```

**執行 FIR 濾波器：**
```bash
docker-compose run --rm fir-filter
```

**進入互動式 shell：**
```bash
docker-compose run --rm qemu
```

---

## 預期輸出

### UART Hello World
```
Timer with period zero, disabling
Hellow World?
qemu-system-arm: terminating on signal 15 from pid 1 (timeout)
```

**說明**：
- ✓ "Hellow World?" 表示程式成功執行
- 警告訊息 "Timer with period zero" 是正常的（QEMU 模擬器特性）

### FIR 濾波器
```
Timer with period zero, disabling
GOOD
qemu-system-arm: terminating on signal 15 from pid 1 (timeout)
```

**說明**：
- ✓ "GOOD" 表示 FIR 濾波器測試通過
- 訊噪比（SNR）符合預期標準

---

## Docker Image 資訊

**Image 名稱**：`cmsis-lm3s-qemu:latest`

**包含軟體**：
- Debian Bookworm Slim
- QEMU 7.2 (ARM 系統模擬器)
- 必要的系統函式庫

**Image 大小**：約 134 MB（安裝後）

**建置指令參數說明**：
```dockerfile
FROM debian:bookworm-slim          # 基礎鏡像
RUN apt-get install qemu-system-arm # 安裝 QEMU
WORKDIR /work                       # 設定工作目錄
```

---

## 常見問題

### Q1: Docker image 不存在怎麼辦？
**A**: 執行建置指令：
```bash
docker build -t cmsis-lm3s-qemu:latest .
```

### Q2: 如何重新建置 image？
**A**: 使用 `--no-cache` 強制重新建置：
```bash
docker build --no-cache -t cmsis-lm3s-qemu:latest .
```

### Q3: 如何刪除舊的 image？
**A**:
```bash
# 使用腳本
./run-examples.sh clean

# 或手動刪除
docker rmi cmsis-lm3s-qemu:latest
```

### Q4: 如何查看 image 詳細資訊？
**A**:
```bash
docker image inspect cmsis-lm3s-qemu:latest
```

### Q5: 程式沒有輸出怎麼辦？
**A**: 檢查：
1. .bin 檔案是否存在：`ls -l examples/*/gcc/*.bin`
2. Docker volume 掛載是否正確
3. 路徑是否正確

### Q6: 如何進入容器除錯？
**A**:
```bash
docker run -it --rm \
    -v $(pwd):/work \
    -w /work \
    cmsis-lm3s-qemu:latest \
    bash

# 在容器內手動執行
cd examples/uart_hello_world/gcc
qemu-system-arm -M lm3s6965evb -nographic -kernel uart_hello_world.bin
# 按 Ctrl+A 然後按 X 離開 QEMU
```

---

## 進階使用

### 掛載為可寫入（開發模式）

如果需要在容器內修改檔案：
```bash
docker run -it --rm \
    -v $(pwd):/work \      # 移除 :ro（唯讀）
    -w /work \
    cmsis-lm3s-qemu:latest \
    bash
```

### 使用 GDB 除錯

**步驟 1**：啟動 QEMU（等待 GDB 連接）
```bash
docker run --rm \
    -v $(pwd):/work:ro \
    -w /work/examples/uart_hello_world/gcc \
    -p 1234:1234 \              # 映射 GDB port
    cmsis-lm3s-qemu:latest \
    qemu-system-arm -M lm3s6965evb -nographic \
        -kernel uart_hello_world.bin -s -S
```

**步驟 2**：在主機上連接 GDB
```bash
arm-none-eabi-gdb examples/uart_hello_world/gcc/uart_hello_world.axf
(gdb) target remote localhost:1234
(gdb) break main
(gdb) continue
```

### 批次執行多個範例

```bash
#!/bin/bash
for example in uart_hello_world arm_fir_example; do
    echo "執行 $example..."
    docker run --rm \
        -v $(pwd):/work:ro \
        -w /work/examples/$example/gcc \
        cmsis-lm3s-qemu:latest \
        timeout 2 qemu-system-arm -M lm3s6965evb -nographic \
            -kernel $(ls *.bin)
    echo "---"
done
```

### 自訂 QEMU 參數

**增加執行時間**：
```bash
timeout 10 qemu-system-arm ...  # 10 秒
```

**啟用 QEMU 追蹤**：
```bash
qemu-system-arm -M lm3s6965evb -nographic \
    -d in_asm,cpu \              # 顯示組合語言和 CPU 狀態
    -kernel uart_hello_world.bin
```

**指定記憶體大小**：
```bash
qemu-system-arm -M lm3s6965evb \
    -m 64M \                     # 64MB RAM
    -kernel uart_hello_world.bin
```

---

## 效能比較

### 傳統方式（每次安裝 QEMU）
```bash
# 需要 20-30 秒下載和安裝
docker run debian:latest bash -c "
    apt-get update &&
    apt-get install -y qemu-system-arm &&
    ...
"
```

### 使用預建 Image
```bash
# 只需 1-2 秒啟動
docker run cmsis-lm3s-qemu:latest ...
```

**節省時間**：約 90% ⚡

---

## 檔案結構

```
CMSIS_LM3S/
├── Dockerfile                  # Docker image 定義
├── .dockerignore              # Docker 忽略檔案
├── docker-compose.yml         # Docker Compose 配置
├── run-examples.sh            # 自動化執行腳本
├── Docker使用指南.md          # 本文檔
└── 執行報告.md                 # 詳細執行報告
```

---

## 最佳實踐

1. **使用唯讀掛載（`:ro`）保護原始碼**
   ```bash
   -v $(pwd):/work:ro  # 推薦
   ```

2. **使用 `--rm` 自動清理容器**
   ```bash
   docker run --rm ...  # 執行後自動刪除
   ```

3. **使用 `timeout` 防止程式無限循環**
   ```bash
   timeout 2 qemu-system-arm ...  # 2 秒後自動終止
   ```

4. **定期更新 image**
   ```bash
   docker build --pull -t cmsis-lm3s-qemu:latest .
   ```

5. **標記版本**
   ```bash
   docker tag cmsis-lm3s-qemu:latest cmsis-lm3s-qemu:v1.0
   ```

---

## 故障排除

### 問題：Permission denied
**解決**：
```bash
chmod +x run-examples.sh
```

### 問題：Image 不存在
**解決**：
```bash
docker build -t cmsis-lm3s-qemu:latest .
```

### 問題：找不到 .bin 檔案
**解決**：
```bash
# 確保已編譯
make clean && make
ls examples/*/gcc/*.bin  # 應該顯示 .bin 檔案
```

### 問題：QEMU 沒有輸出
**解決**：
```bash
# 移除 timeout，手動觀察
docker run -it --rm \
    -v $(pwd):/work:ro \
    -w /work/examples/uart_hello_world/gcc \
    cmsis-lm3s-qemu:latest \
    qemu-system-arm -M lm3s6965evb -nographic -kernel uart_hello_world.bin
# 按 Ctrl+A 然後 X 離開
```

---

## 相關資源

- [QEMU 文檔](https://www.qemu.org/docs/master/)
- [Docker 官方文檔](https://docs.docker.com/)
- [CMSIS 官方網站](https://arm-software.github.io/CMSIS_5/)
- [執行報告.md](./執行報告.md) - 完整執行流程

---

**版本**：1.0
**最後更新**：2025年11月15日
