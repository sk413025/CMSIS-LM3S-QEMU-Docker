# CMSIS_LM3S 詳細安裝與執行指南

> ARM Cortex-M3 LM3S6965 微控制器開發環境完整設置教學

## 目錄

- [專案簡介](#專案簡介)
- [系統需求](#系統需求)
- [快速開始](#快速開始)
- [詳細安裝步驟](#詳細安裝步驟)
  - [步驟 1: 安裝 ARM 交叉編譯工具鏈](#步驟-1-安裝-arm-交叉編譯工具鏈)
  - [步驟 2: 編譯專案](#步驟-2-編譯專案)
  - [步驟 3: 建置 Docker 環境](#步驟-3-建置-docker-環境)
  - [步驟 4: 執行範例程式](#步驟-4-執行範例程式)
- [使用方式](#使用方式)
- [故障排除](#故障排除)
- [進階主題](#進階主題)

---

## 專案簡介

CMSIS_LM3S 是一個針對 **Texas Instruments LM3S6965** (ARM Cortex-M3) 微控制器的裸機開發專案，包含：

- ✅ **CMSIS DSP 函式庫**：271 個訊號處理函數
- ✅ **硬體抽象層**：LM3S 系列微控制器支援
- ✅ **範例程式**：UART 通訊、FIR 濾波器
- ✅ **QEMU 模擬**：無需實體硬體即可測試

**適用對象**：
- 嵌入式系統開發者
- ARM Cortex-M 學習者
- 數位訊號處理工程師
- 無實體硬體的開發者

---

## 系統需求

### 必要條件

| 項目 | 需求 | 說明 |
|------|------|------|
| **作業系統** | Linux (CentOS/RHEL 9+, Debian, Ubuntu) | 本指南以 CentOS 9 為例 |
| **Docker** | 28.0+ | 用於執行 QEMU 模擬器 |
| **磁碟空間** | 至少 2 GB | 包含工具鏈和 Docker image |
| **網路** | 需要 | 下載套件和 Docker image |

### 可選條件

- **實體 LM3S 開發板**：可將編譯結果燒錄到真實硬體
- **GDB 除錯器**：用於程式除錯

---

## 快速開始

**只需 3 個指令即可開始！**

```bash
# 1. 安裝 ARM 工具鏈
sudo dnf install -y arm-none-eabi-gcc-cs arm-none-eabi-newlib

# 2. 編譯專案
make clean && make

# 3. 使用 Docker 執行
docker build -t cmsis-lm3s-qemu:latest .
docker run --rm -v $(pwd):/work:ro -w /work/examples/uart_hello_world/gcc \
    cmsis-lm3s-qemu:latest \
    timeout 2 qemu-system-arm -M lm3s6965evb -nographic -kernel uart_hello_world.bin
```

**預期輸出**：
```
Hellow World?
```

---

## 詳細安裝步驟

### 前置準備

**1. 確認系統版本**
```bash
cat /etc/os-release
uname -m
```

**輸出範例**：
```
NAME="CentOS Stream"
VERSION="9"
x86_64
```

**2. 更新系統套件**
```bash
sudo dnf update -y
```

**3. 確認 Docker 已安裝**
```bash
docker --version
```

**輸出範例**：
```
Docker version 28.0.4, build b8034c0
```

**如果未安裝 Docker**：
```bash
# CentOS/RHEL
sudo dnf install -y docker-ce docker-ce-cli containerd.io

# Debian/Ubuntu
sudo apt-get install -y docker.io
```

---

### 步驟 1: 安裝 ARM 交叉編譯工具鏈

#### 1.1 檢查並啟用 EPEL 倉庫（CentOS/RHEL 適用）

```bash
# 檢查 EPEL 是否已啟用
dnf repolist | grep epel
```

**如果沒有輸出，需要安裝 EPEL**：
```bash
sudo dnf install -y epel-release
```

**驗證**：
```bash
dnf repolist epel
```

#### 1.2 搜尋可用的 ARM 工具鏈套件

```bash
dnf search arm-none-eabi
```

**應該看到**：
```
arm-none-eabi-binutils-cs.x86_64 : GNU Binutils for ARM
arm-none-eabi-gcc-cs.x86_64 : GNU GCC for ARM
arm-none-eabi-gcc-cs-c++.x86_64 : GNU G++ for ARM
arm-none-eabi-newlib.noarch : C library for embedded systems
```

#### 1.3 安裝 ARM 工具鏈

```bash
sudo dnf install -y \
    arm-none-eabi-binutils-cs \
    arm-none-eabi-gcc-cs \
    arm-none-eabi-gcc-cs-c++ \
    arm-none-eabi-newlib
```

**安裝過程**：
```
總下載大小: 234 MB
安裝大小: 1.4 GB
...
安裝完成！
```

#### 1.4 驗證安裝

```bash
# 檢查編譯器
arm-none-eabi-gcc --version

# 檢查連結器
arm-none-eabi-ld --version

# 檢查打包工具
arm-none-eabi-ar --version

# 檢查目標檔案轉換工具
arm-none-eabi-objcopy --version
```

**預期輸出**（以 gcc 為例）：
```
arm-none-eabi-gcc (Fedora 12.4.0-1.el9) 12.4.0
Copyright (C) 2022 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.
```

**✅ 如果看到版本資訊，表示安裝成功！**

---

### 步驟 2: 編譯專案

#### 2.1 進入專案目錄

```bash
cd /path/to/CMSIS_LM3S
```

#### 2.2 清理舊的建置檔案

```bash
make clean
```

**輸出**：
```
make[1]: Entering directory '.../examples'
make[2]: Entering directory '.../arm_fir_example'
make[2]: Leaving directory '.../arm_fir_example'
make[2]: Entering directory '.../uart_hello_world'
make[2]: Leaving directory '.../uart_hello_world'
make[1]: Leaving directory '.../examples'
```

#### 2.3 編譯所有範例

```bash
make
```

**編譯過程**（應該看到）：
```
make[2]: Entering directory '.../uart_hello_world'
  CC    uart_hello_world.c
  CC    startup_gcc.c
  CC    ../../lm3s/system_lm3s.c
  LD    gcc/uart_hello_world.axf
ALL IS GOOD, CHILL OUT          ← 成功標誌！
make[2]: Leaving directory '.../uart_hello_world'

make[2]: Entering directory '.../arm_fir_example'
  CC    arm_fir_example_f32.c
  CC    arm_fir_data.c
  CC    math_helper.c
  CC    startup_gcc.c
  CC    ../../lm3s/system_lm3s.c
  CC    ../../CMSIS/DSP_Lib/Source/FilteringFunctions/arm_fir_f32.c
  CC    ../../CMSIS/DSP_Lib/Source/FilteringFunctions/arm_fir_init_f32.c
  LD    gcc/arm_fir_example_f32.axf
ALL IS GOOD, CHILL OUT          ← 成功標誌！
make[2]: Leaving directory '.../arm_fir_example'
```

**✅ 看到 "ALL IS GOOD, CHILL OUT" 表示編譯成功！**

#### 2.4 驗證編譯產物

```bash
# 檢查 UART 範例
ls -lh examples/uart_hello_world/gcc/*.bin

# 檢查 FIR 濾波器範例
ls -lh examples/arm_fir_example/gcc/*.bin
```

**預期輸出**：
```
-rwxr-xr-x  uart_hello_world.bin  (423 bytes)
-rwxr-xr-x  arm_fir_example_f32.bin  (13K)
```

**✅ 如果看到 .bin 檔案，表示編譯產物生成成功！**

#### 2.5 編譯警告說明

**可能看到的警告**：
```
warning: ISO C forbids braced-groups within expressions [-Wpedantic]
```

**說明**：
- 這是正常的警告
- 來自 CMSIS 官方程式碼使用的 GCC 擴展語法
- **不影響功能，可以忽略**

---

### 步驟 3: 建置 Docker 環境

#### 3.1 查看 Dockerfile

```bash
cat Dockerfile
```

**內容說明**：
```dockerfile
FROM debian:bookworm-slim        # 使用精簡版 Debian
RUN apt-get update &&            # 更新套件列表
    apt-get install -y           # 安裝
        qemu-system-arm          # QEMU ARM 模擬器
        ca-certificates          # SSL 憑證
WORKDIR /work                    # 設定工作目錄
CMD ["qemu-system-arm", "--version"]
```

#### 3.2 建置 Docker Image

```bash
docker build -t cmsis-lm3s-qemu:latest .
```

**建置過程**（約 1-2 分鐘）：
```
[1/3] FROM docker.io/library/debian:bookworm-slim
[2/3] RUN apt-get update && apt-get install -y qemu-system-arm
  ↳ 下載 QEMU 和依賴套件...
  ↳ 安裝 59 個套件...
  ↳ 總大小：134 MB
[3/3] WORKDIR /work
Successfully tagged cmsis-lm3s-qemu:latest
```

**✅ 看到 "Successfully tagged" 表示建置成功！**

#### 3.3 驗證 Docker Image

```bash
# 檢查 image 是否存在
docker images | grep cmsis-lm3s-qemu
```

**輸出**：
```
cmsis-lm3s-qemu   latest   7655bada9b6a   1 minute ago   134MB
```

```bash
# 測試 QEMU 版本
docker run --rm cmsis-lm3s-qemu:latest qemu-system-arm --version
```

**輸出**：
```
QEMU emulator version 7.2.0 (Debian 1:7.2+dfsg-7+deb12u16)
```

**✅ 如果看到版本資訊，Docker 環境就緒！**

---

### 步驟 4: 執行範例程式

#### 方法 A: 使用自動化腳本（最簡單）

**4A.1 賦予執行權限**
```bash
chmod +x run-examples.sh
```

**4A.2 執行所有範例**
```bash
./run-examples.sh all
```

**輸出**：
```
✓ Docker 已安裝
======================================
建置 Docker Image
======================================
✓ 跳過建置，使用現有 image
======================================
執行 UART Hello World 範例
======================================
執行中...
Hellow World?
✓ UART 範例執行完成

======================================
執行 FIR 濾波器範例
======================================
執行中...
GOOD
✓ FIR 濾波器範例執行完成
```

**4A.3 只執行單一範例**
```bash
# UART 範例
./run-examples.sh uart

# FIR 濾波器
./run-examples.sh fir
```

---

#### 方法 B: 使用 Docker 命令（自訂性高）

**4B.1 執行 UART Hello World**
```bash
docker run --rm \
    -v $(pwd):/work:ro \
    -w /work/examples/uart_hello_world/gcc \
    cmsis-lm3s-qemu:latest \
    timeout 2 qemu-system-arm \
        -M lm3s6965evb \
        -nographic \
        -kernel uart_hello_world.bin
```

**指令參數說明**：
- `--rm`：執行後自動刪除容器
- `-v $(pwd):/work:ro`：掛載當前目錄到容器（唯讀）
- `-w /work/examples/uart_hello_world/gcc`：設定工作目錄
- `timeout 2`：2 秒後自動終止（因為程式會無限循環）
- `-M lm3s6965evb`：模擬 LM3S6965 評估板
- `-nographic`：終端模式（不使用圖形界面）
- `-kernel uart_hello_world.bin`：載入二進位檔

**預期輸出**：
```
Timer with period zero, disabling    ← QEMU 警告（正常）
Hellow World?                         ← 程式輸出（成功！）
qemu-system-arm: terminating on signal 15
```

**✅ 看到 "Hellow World?" 表示執行成功！**

**4B.2 執行 FIR 濾波器範例**
```bash
docker run --rm \
    -v $(pwd):/work:ro \
    -w /work/examples/arm_fir_example/gcc \
    cmsis-lm3s-qemu:latest \
    timeout 2 qemu-system-arm \
        -M lm3s6965evb \
        -nographic \
        -kernel arm_fir_example_f32.bin
```

**預期輸出**：
```
Timer with period zero, disabling    ← QEMU 警告（正常）
GOOD                                  ← 測試通過（成功！）
qemu-system-arm: terminating on signal 15
```

**✅ 看到 "GOOD" 表示 FIR 濾波器測試通過！**

---

#### 方法 C: 使用 Docker Compose（適合重複執行）

**4C.1 執行 UART 範例**
```bash
docker-compose run --rm uart-hello
```

**4C.2 執行 FIR 濾波器**
```bash
docker-compose run --rm fir-filter
```

**4C.3 進入互動式環境**
```bash
docker-compose run --rm qemu bash

# 在容器內
cd examples/uart_hello_world/gcc
qemu-system-arm -M lm3s6965evb -nographic -kernel uart_hello_world.bin
# 按 Ctrl+A 然後 X 離開 QEMU
```

---

## 使用方式

### 日常開發流程

```bash
# 1. 修改原始碼
vim examples/uart_hello_world/uart_hello_world.c

# 2. 重新編譯
make clean && make

# 3. 執行測試
./run-examples.sh uart

# 4. 檢查結果
# 應該看到新的輸出
```

### 新增範例專案

**1. 複製現有範例**
```bash
cp -r examples/uart_hello_world examples/my_project
```

**2. 修改 Makefile**
```bash
cd examples/my_project
vim Makefile
# 修改專案名稱等參數
```

**3. 編譯新專案**
```bash
cd ../..
make
```

### 燒錄到實體硬體

如果你有 LM3S6965 開發板：

**1. 準備燒錄工具**
```bash
# 安裝 lm4flash（LM3S/LM4F 燒錄工具）
sudo dnf install lm4flash  # CentOS/RHEL
sudo apt-get install lm4flash  # Debian/Ubuntu
```

**2. 連接開發板**
```bash
# 透過 USB 連接開發板
# 檢查設備
ls /dev/ttyACM*
```

**3. 燒錄程式**
```bash
lm4flash examples/uart_hello_world/gcc/uart_hello_world.bin
```

**4. 使用串口監視器查看輸出**
```bash
screen /dev/ttyACM0 115200
# 或
minicom -D /dev/ttyACM0 -b 115200
```

---

## 故障排除

### 問題 1: `arm-none-eabi-gcc: command not found`

**原因**：ARM 工具鏈未安裝或不在 PATH 中

**解決方案**：
```bash
# 檢查是否已安裝
which arm-none-eabi-gcc

# 如果沒有輸出，重新安裝
sudo dnf install -y arm-none-eabi-gcc-cs arm-none-eabi-newlib

# 驗證
arm-none-eabi-gcc --version
```

---

### 問題 2: `make: *** No targets specified and no makefile found`

**原因**：不在專案根目錄

**解決方案**：
```bash
# 檢查當前目錄
pwd

# 確認 Makefile 存在
ls -l Makefile

# 如果不在正確目錄，切換到專案根目錄
cd /path/to/CMSIS_LM3S
```

---

### 問題 3: 編譯錯誤 `fatal error: arm_math.h: No such file or directory`

**原因**：Include 路徑不正確

**解決方案**：
```bash
# 檢查 CMSIS 目錄是否存在
ls -l CMSIS/Include/arm_math.h

# 如果不存在，可能需要重新克隆專案
git clone <repository-url>

# 檢查 Makefile 中的 IPATH 設定
grep IPATH examples/uart_hello_world/Makefile
```

---

### 問題 4: Docker image 建置失敗

**原因**：網路問題或 Docker 配置問題

**解決方案**：
```bash
# 檢查 Docker 服務
sudo systemctl status docker

# 如果未啟動
sudo systemctl start docker

# 測試網路
ping download.debian.org

# 清理 Docker 快取後重試
docker system prune -a
docker build --no-cache -t cmsis-lm3s-qemu:latest .
```

---

### 問題 5: QEMU 執行無輸出

**原因**：.bin 檔案不存在或路徑錯誤

**解決方案**：
```bash
# 檢查 .bin 檔案是否存在
ls -l examples/uart_hello_world/gcc/uart_hello_world.bin

# 如果不存在，重新編譯
make clean && make

# 手動進入容器測試
docker run -it --rm \
    -v $(pwd):/work \
    -w /work/examples/uart_hello_world/gcc \
    cmsis-lm3s-qemu:latest bash

# 在容器內手動執行
ls -l uart_hello_world.bin  # 確認檔案存在
qemu-system-arm -M lm3s6965evb -nographic -kernel uart_hello_world.bin
```

---

### 問題 6: 權限錯誤 `Permission denied`

**原因**：檔案權限不足

**解決方案**：
```bash
# 修復腳本權限
chmod +x run-examples.sh

# 修復連結腳本權限
chmod +x examples/*/gcc/*.ld

# 確保 Docker 可以存取檔案
sudo usermod -aG docker $USER
# 重新登入以套用群組變更
```

---

## 進階主題

### 使用 GDB 除錯

**步驟 1**：重新編譯（含除錯符號）
```bash
make clean
make DEBUG=1
```

**步驟 2**：啟動 QEMU（等待 GDB 連接）
```bash
docker run --rm \
    -v $(pwd):/work:ro \
    -w /work/examples/uart_hello_world/gcc \
    -p 1234:1234 \
    cmsis-lm3s-qemu:latest \
    qemu-system-arm -M lm3s6965evb -nographic \
        -kernel uart_hello_world.bin -s -S
```

**參數說明**：
- `-s`：在 port 1234 啟動 GDB server
- `-S`：啟動時暫停，等待 GDB 連接
- `-p 1234:1234`：映射 GDB port

**步驟 3**：另開終端，啟動 GDB
```bash
arm-none-eabi-gdb examples/uart_hello_world/gcc/uart_hello_world.axf
```

**GDB 指令**：
```gdb
# 連接到 QEMU
(gdb) target remote localhost:1234

# 設定中斷點
(gdb) break main
(gdb) break uart_hello_world.c:42

# 開始執行
(gdb) continue

# 單步執行
(gdb) step
(gdb) next

# 查看變數
(gdb) print variable_name

# 查看暫存器
(gdb) info registers

# 查看記憶體
(gdb) x/16x 0x20000000

# 離開
(gdb) quit
```

---

### 效能優化

**編譯優化等級**：
```bash
# 修改 makedefs 檔案
vim makedefs

# 找到 CFLAGS 行，修改優化等級
-O0    # 無優化（預設，除錯友善）
-O1    # 基本優化
-O2    # 進階優化（推薦）
-O3    # 最高優化
-Os    # 優化程式大小
```

**查看程式大小**：
```bash
arm-none-eabi-size examples/uart_hello_world/gcc/uart_hello_world.axf
```

**輸出**：
```
   text    data     bss     dec     hex filename
   1234      56     128    1418     58a uart_hello_world.axf
```

**說明**：
- `text`：程式碼段大小
- `data`：已初始化資料段
- `bss`：未初始化資料段
- `dec/hex`：總大小（十進位/十六進位）

---

### 程式碼分析

**反組譯**：
```bash
arm-none-eabi-objdump -d examples/uart_hello_world/gcc/uart_hello_world.axf > disasm.txt
less disasm.txt
```

**查看符號表**：
```bash
arm-none-eabi-nm examples/uart_hello_world/gcc/uart_hello_world.axf
```

**查看段資訊**：
```bash
arm-none-eabi-objdump -h examples/uart_hello_world/gcc/uart_hello_world.axf
```

**產生記憶體映射**：
```bash
arm-none-eabi-objdump -x examples/uart_hello_world/gcc/uart_hello_world.axf > memmap.txt
```

---

### 自訂 DSP 應用

**使用 FFT 範例**：

```c
#include "arm_math.h"

#define FFT_SIZE 256

arm_rfft_fast_instance_f32 fft_instance;
float32_t input[FFT_SIZE];
float32_t output[FFT_SIZE];

int main(void) {
    // 初始化 FFT
    arm_rfft_fast_init_f32(&fft_instance, FFT_SIZE);

    // 準備輸入訊號（例如：正弦波）
    for(int i = 0; i < FFT_SIZE; i++) {
        input[i] = arm_sin_f32(2 * PI * 10 * i / FFT_SIZE);
    }

    // 執行 FFT
    arm_rfft_fast_f32(&fft_instance, input, output, 0);

    // 處理 FFT 結果...
}
```

**編譯時需要連結的 DSP 模組**：
在 Makefile 中加入：
```makefile
VPATH += ../../CMSIS/DSP_Lib/Source/TransformFunctions
VPATH += ../../CMSIS/DSP_Lib/Source/CommonTables

gcc/my_fft_app.axf: gcc/arm_rfft_fast_f32.o
gcc/my_fft_app.axf: gcc/arm_rfft_fast_init_f32.o
gcc/my_fft_app.axf: gcc/arm_cfft_f32.o
```

---

## 檔案結構說明

```
CMSIS_LM3S/
├── CMSIS/                          # ARM CMSIS 標準庫
│   ├── DSP_Lib/                    # DSP 函式庫
│   │   └── Source/                 # 271 個 DSP 原始檔
│   │       ├── BasicMathFunctions/
│   │       ├── FilteringFunctions/
│   │       ├── TransformFunctions/
│   │       ├── MatrixFunctions/
│   │       └── ...
│   └── Include/                    # CMSIS 標頭檔
│       ├── arm_math.h
│       ├── core_cm3.h
│       └── ...
│
├── lm3s/                           # LM3S 硬體抽象層
│   ├── lm3s_cmsis.h               # 暫存器定義
│   ├── system_lm3s.c              # 系統初始化
│   └── system_lm3s.h
│
├── examples/                       # 範例程式
│   ├── uart_hello_world/          # UART 範例
│   │   ├── uart_hello_world.c
│   │   ├── startup_gcc.c
│   │   ├── uart_hello_world.ld
│   │   ├── lm3s_config.h
│   │   ├── Makefile
│   │   └── gcc/                   # 編譯產物目錄
│   │       ├── uart_hello_world.bin
│   │       ├── uart_hello_world.axf
│   │       └── *.o
│   │
│   └── arm_fir_example/           # FIR 濾波器範例
│       ├── arm_fir_example_f32.c
│       ├── arm_fir_data.c
│       ├── math_helper.c
│       ├── startup_gcc.c
│       ├── arm_fir_example_f32.ld
│       ├── lm3s_config.h
│       ├── Makefile
│       └── gcc/
│           ├── arm_fir_example_f32.bin
│           └── ...
│
├── Dockerfile                      # Docker image 定義
├── .dockerignore                   # Docker 忽略檔案
├── docker-compose.yml              # Docker Compose 配置
├── run-examples.sh                 # 自動化執行腳本
│
├── Makefile                        # 頂層 Makefile
├── makedefs                        # 共用建置定義
│
├── README.md                       # 原始 README
├── README-詳細安裝執行指南.md      # 本文檔
├── Docker使用指南.md               # Docker 使用說明
├── 執行報告.md                     # 完整執行報告
└── LMI_EULA.txt                   # 授權條款
```

---

## 常見問題 (FAQ)

### Q1: 為什麼輸出是 "Hellow" 而不是 "Hello"？
**A**: 這是原始程式碼中的拼字錯誤（可能是故意的），不影響功能。你可以修改原始碼：
```c
// uart_hello_world.c
print_uart0("Hello World?\r\n");  // 修改拼字
```

### Q2: 可以在 Windows 上執行嗎？
**A**: 可以！使用以下方式：
1. **WSL2**（推薦）：在 WSL2 中按照本指南操作
2. **Docker Desktop**：直接使用 Docker Desktop for Windows
3. **MinGW**：安裝 MinGW + arm-none-eabi-gcc

### Q3: 支援哪些 ARM Cortex-M 晶片？
**A**:
- **直接支援**：LM3S 系列（LM3S6965, LM3S9B96 等）
- **可移植**：Cortex-M3/M4/M7（需修改啟動檔和連結腳本）

### Q4: 如何新增自己的周邊驅動？
**A**:
1. 參考 `lm3s/lm3s_cmsis.h` 中的暫存器定義
2. 在 `lm3s/` 目錄下新增驅動檔案
3. 在 Makefile 中加入編譯規則

### Q5: 可以使用 RTOS 嗎？
**A**: 可以！推薦：
- **FreeRTOS**：最流行的嵌入式 RTOS
- **Zephyr**：Linux Foundation 支援
- **RT-Thread**：中國開源 RTOS

### Q6: 效能如何？
**A**:
- **QEMU 模擬**：約為實體硬體的 10-50%
- **實體 LM3S6965**：50 MHz Cortex-M3
- **DSP 函式庫**：使用 ARM 優化的彙編代碼

---

## 相關資源

### 官方文檔
- [ARM CMSIS 官網](https://arm-software.github.io/CMSIS_5/)
- [CMSIS-DSP 函式庫](https://arm-software.github.io/CMSIS_5/DSP/html/index.html)
- [LM3S6965 資料手冊](https://www.ti.com/product/LM3S6965)
- [QEMU 文檔](https://www.qemu.org/docs/master/)

### 教學資源
- [ARM Cortex-M 編程入門](https://interrupt.memfault.com/blog/zero-to-main-1)
- [嵌入式 C 編程最佳實踐](https://barrgroup.com/embedded-systems/books/embedded-c-coding-standard)
- [數位訊號處理教程](https://www.dspguide.com/)

### 開發工具
- [GCC ARM Embedded](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm)
- [OpenOCD](http://openocd.org/) - 開源除錯器
- [STM32CubeIDE](https://www.st.com/en/development-tools/stm32cubeide.html) - IDE（支援 Cortex-M）

---

## 貢獻與反饋

如有問題或建議，歡迎：
1. 提交 GitHub Issue
2. 發送 Pull Request
3. 參考 [執行報告.md](./執行報告.md) 了解完整技術細節

---

## 授權

本專案基於原始 Stellaris CMSIS Package 授權。
詳見 [LMI_EULA.txt](./LMI_EULA.txt)

CMSIS DSP 函式庫採用 BSD 授權。

---

**版本**：1.0
**最後更新**：2025年11月15日
**維護者**：CMSIS_LM3S Project Team

**下一步**：
1. ✅ 閱讀本文檔完成安裝
2. ✅ 執行範例程式驗證環境
3. ✅ 查看 [執行報告.md](./執行報告.md) 了解技術細節
4. ✅ 查看 [Docker使用指南.md](./Docker使用指南.md) 進階使用

**祝開發順利！** 🚀
