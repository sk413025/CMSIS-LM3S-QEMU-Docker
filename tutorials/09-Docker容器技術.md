# 模組 09：Docker 容器技術

> 使用 Docker 建立一致的開發環境

**對應專案檔案**: [Dockerfile](../Dockerfile), [Dockerfile.gdb](../Dockerfile.gdb), [docker-compose.yml](../docker-compose.yml)

## 📌 學習目標
- ✅ 理解容器化概念與優勢
- ✅ 深入學習 Dockerfile 撰寫
- ✅ 掌握 Docker 基本指令
- ✅ 使用 docker-compose 管理多容器
- ✅ 建立一致的嵌入式開發環境

---

## 開始之前：為什麼需要 Docker？

想像你是一位**廚師**，正在準備一道複雜的料理：

```
問題：環境不一致導致的災難
════════════════════════════════════════

在餐廳廚房（開發者 A）:
  🔥 瓦斯爐 (編譯器版本 11.2)
  🍳 專業鍋具 (ARM GCC)
  📏 精確量匙 (QEMU 6.2)
  → 料理完美 ✓

在家裡廚房（開發者 B）:
  🔥 電磁爐 (編譯器版本 9.4)
  🍳 普通鍋具 (缺少工具)
  📏 隨便估計 (QEMU 版本不符)
  → 料理失敗 ✗

在露營地（開發者 C - Mac）:
  🔥 營火 (完全不同的系統)
  🍳 鋁罐 (工具不相容)
  📏 沒有量具 (缺少套件)
  → 無法烹飪 ✗
```

**這就是軟體開發的痛點**：

```
開發者 A (Ubuntu 22.04):
  $ make
  ✓ 編譯成功
  ✓ 所有測試通過

開發者 B (CentOS 9):
  $ make
  ✗ arm-none-eabi-gcc: command not found
  ✗ QEMU 版本太舊
  ✗ Python 3.8 需要 3.10+

開發者 C (macOS):
  $ make
  ✗ glibc 不相容
  ✗ 路徑分隔符號不同
  ✗ make 版本不符
```

**Docker 的解決方案**：給每個人**同一個廚房** 🏭

```
所有開發者使用同一個 Docker Image:
┌─────────────────────────────────┐
│  📦 標準化廚房容器               │
│  ✓ ARM GCC 11.2                 │
│  ✓ QEMU 6.2                     │
│  ✓ Python 3.10                  │
│  ✓ Make 4.3                     │
│  ✓ 所有工具完全一致              │
└─────────────────────────────────┘
         ↓
開發者 A, B, C 都能成功編譯！
```

---

## 1. 容器化概念

### 1.1 什麼是容器？

**容器 = 輕量級、隔離的執行環境**

**類比 1：貨櫃 (Shipping Container)**

```
傳統貨運（沒有容器化）:
┌─────────┐ ┌─────┐ ┌───────┐
│  香蕉   │ │ 汽車│ │  電腦 │
│ (需特殊 │ │(需固│ │ (需防│
│  通風)  │ │定架)│ │  震動)│
└─────────┘ └─────┘ └───────┘
  → 每種貨物需要不同處理方式
  → 運輸效率低
  → 容易損壞

貨櫃化運輸（容器化）:
┌─────────────────────────────┐
│ 📦 標準貨櫃                  │
│  (20 尺 × 8 尺 × 8.5 尺)    │
│  ┌──────┐ ┌────┐ ┌──────┐  │
│  │香蕉  │ │汽車│ │電腦  │  │
│  └──────┘ └────┘ └──────┘  │
└─────────────────────────────┘
  → 所有貨物使用相同容器
  → 堆疊、運輸、儲存標準化
  → 效率提升 10 倍以上！
```

**類比 2：套房公寓**

```
虛擬機 = 獨棟別墅:
┌──────────────────┐
│ 🏠 獨立房屋      │
│  ✓ 獨立電力系統  │
│  ✓ 獨立水管系統  │
│  ✓ 獨立暖氣系統  │
│  ✓ 獨立地基      │
│  ✗ 建造成本高    │
│  ✗ 維護成本高    │
└──────────────────┘

容器 = 套房:
┌──────────────────┐
│ 🏢 大樓內的房間  │
│  ✓ 共用電力系統  │
│  ✓ 共用水管系統  │
│  ✓ 共用暖氣系統  │
│  ✓ 共用地基      │
│  ✓ 建造快速      │
│  ✓ 維護便宜      │
└──────────────────┘
```

### 1.2 容器 vs 虛擬機詳細比較

```
═══════════════════════════════════════════════════════
              虛擬機 (VM)              容器 (Container)
───────────────────────────────────────────────────────
架構圖:

┌───────────────────────┐  ┌─────────────────────────┐
│ App A │ App B │ App C │  │ App A │ App B │ App C   │
│ ─────────────────────│  │ ───────────────────────│
│ Libs  │ Libs  │ Libs  │  │ 容器引擎 (Docker)       │
│ ─────────────────────│  │ ───────────────────────│
│Guest OS│Guest OS│Guest│  │ Host OS (Linux)        │
│ ─────────────────────│  │ ───────────────────────│
│   Hypervisor (VMware) │  │ 硬體                    │
│ ─────────────────────│  └─────────────────────────┘
│ Host OS               │
│ ─────────────────────│
│ 硬體                  │
└───────────────────────┘

───────────────────────────────────────────────────────
特性比較:
───────────────────────────────────────────────────────
隔離層級   作業系統層級           程序層級
           (完全隔離)            (共享核心)

啟動時間   秒到分鐘 (10-60s)     毫秒到秒 (0.1-5s)
           需要開機整個 OS       直接啟動程序

記憶體     GB 級別 (1-4 GB)      MB 級別 (10-200 MB)
           每個 VM 獨立 OS       共享 Host OS

儲存空間   10-100 GB             10-500 MB
           完整 OS + 應用         只有應用 + 必要函式庫

CPU 效能   有虛擬化開銷 (~5%)    接近原生 (~2%)
           透過 Hypervisor       直接使用 Host CPU

移植性     較差                  優秀
           需要相同 Hypervisor   只需 Docker Engine

密度       低 (1台主機 10-20 VM) 高 (1台主機 100-1000 容器)
           記憶體是瓶頸          輕量化

管理複雜度 高                    中
           需管理多個 OS         統一管理

適用場景   完全隔離需求          微服務、CI/CD
           不同 OS 需求          快速部署
           舊有應用遷移          開發環境一致性
═══════════════════════════════════════════════════════
```

**實際數字對比**（執行 QEMU ARM 模擬器）:

```
虛擬機方案:
  建立時間: 2-3 分鐘 (下載 ISO、安裝 OS)
  啟動時間: 30-60 秒
  記憶體: 512 MB - 2 GB
  儲存: 5-10 GB
  總時間: 第一次使用需要 5-10 分鐘

Docker 容器方案:
  建立時間: 1-2 分鐘 (下載 base image、安裝套件)
  啟動時間: 0.5-2 秒
  記憶體: 50-100 MB
  儲存: 200-400 MB
  總時間: 第一次使用需要 2-3 分鐘

省下: 70-80% 時間、80-90% 儲存空間！
```

### 1.3 Docker 核心概念

**Image (映像檔) vs Container (容器)**

```
類比：CD-ROM vs 音樂播放

Image = CD-ROM:
  ┌─────────────┐
  │ 💿 光碟片   │
  │  • 唯讀     │
  │  • 可複製   │
  │  • 模板     │
  └─────────────┘

  特性:
    ✓ 不可修改 (唯讀)
    ✓ 可以建立多個副本
    ✓ 儲存在硬碟上
    ✓ 佔用空間 (MB/GB)

Container = 音樂播放中:
  ┌─────────────┐
  │ 🎵 播放中   │
  │  • 執行中   │
  │  • 可暫停   │
  │  • 可停止   │
  └─────────────┘

  特性:
    ✓ 可讀寫 (執行時狀態)
    ✓ 從 Image 建立
    ✓ 執行在記憶體中
    ✓ 停止後狀態消失*

*註: 除非使用 Volume 持久化儲存
```

**物件導向類比**：

```python
# Image = Class (類別)
class ARMDevEnvironment:
    def __init__(self):
        self.gcc_version = "11.2"
        self.qemu_version = "6.2"
        self.tools = ["make", "gdb", "binutils"]

    def compile(self, source):
        return f"arm-none-eabi-gcc {source}"

# Container = Instance (實例)
container1 = ARMDevEnvironment()  # 開發者 A 的環境
container2 = ARMDevEnvironment()  # 開發者 B 的環境
container3 = ARMDevEnvironment()  # 開發者 C 的環境

# 所有實例都有相同的工具和配置！
```

**關鍵差異總結**:

```
┌─────────────────────────────────────────────────┐
│              Image              Container       │
├─────────────────────────────────────────────────┤
│ 靜態            vs            動態              │
│ 模板            vs            實例              │
│ 唯讀            vs            可讀寫            │
│ 儲存在硬碟      vs            執行在記憶體      │
│ docker images   vs            docker ps        │
│ docker build    vs            docker run       │
│ 一個可建立多個  vs            獨立的執行環境    │
└─────────────────────────────────────────────────┘
```

---

## 2. Dockerfile 深入解析

### 2.1 什麼是 Dockerfile？

**Dockerfile = 食譜 (Recipe)**

```
傳統食譜:
═══════════════════════════════════════
巧克力蛋糕製作步驟

1. 準備烤箱 (預熱至 180°C)
2. 取 2 杯麵粉、1 杯糖、3 顆蛋
3. 混合所有材料
4. 倒入烤盤
5. 烘烤 30 分鐘
═══════════════════════════════════════

Dockerfile (容器食譜):
═══════════════════════════════════════
FROM debian:bookworm-slim         # 1. 準備基底
RUN apt-get update                # 2. 取得工具清單
RUN apt-get install -y gcc make   # 3. 安裝工具
COPY source/ /app/                # 4. 複製程式碼
WORKDIR /app                      # 5. 設定工作目錄
CMD ["make", "run"]               # 6. 執行程式
═══════════════════════════════════════

兩者都是:
  ✓ 可重複執行的指令集
  ✓ 任何人照著做都能得到相同結果
  ✓ 可以分享給其他人
```

### 2.2 專案 Dockerfile 逐行解析

**QEMU 環境 Dockerfile**:

```dockerfile
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y \
    qemu-system-arm \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /work
CMD ["qemu-system-arm", "--version"]
```

**第 1 行：FROM debian:bookworm-slim**

```
FROM = 選擇基底 Image

類比: 選擇房子的地基
  ┌──────────────────────────────┐
  │ debian:bookworm-slim         │
  │  • Debian 12 (穩定版)        │
  │  • slim = 精簡版 (~80 MB)    │
  │  • 包含基本工具 (bash, apt)  │
  └──────────────────────────────┘

其他選擇:
  ubuntu:22.04      → Ubuntu (更常見，但較大 ~200 MB)
  alpine:latest     → Alpine Linux (超小 ~5 MB，但使用 musl libc)
  scratch           → 完全空白 (只有你的程式，~0 MB)

為什麼選 debian:bookworm-slim?
  ✓ 穩定性高 (Debian 以穩定著稱)
  ✓ 套件豐富 (apt 有大量預編譯套件)
  ✓ 大小適中 (80 MB vs Ubuntu 200 MB)
  ✓ 相容性好 (glibc，與大多數軟體相容)
```

**第 2-5 行：RUN apt-get update && apt-get install ...**

```
RUN = 執行命令 (在建置時)

拆解命令:
  apt-get update
    └─ 更新套件清單 (類似 "去市場看看有什麼新鮮的")

  &&
    └─ 邏輯 AND (前一個成功才執行下一個)

  apt-get install -y
    └─ 安裝套件
    └─ -y = yes，自動確認 (不需要人工輸入 y/n)

  qemu-system-arm
    └─ ARM 系統模擬器

  ca-certificates
    └─ SSL 憑證 (用於 HTTPS 連線)

  &&

  rm -rf /var/lib/apt/lists/*
    └─ 刪除 apt 快取，減少 image 大小 (~40 MB)

為什麼用 &&  連接？
  ✓ 減少 Docker 層數 (每個 RUN 建立一層)
  ✓ 確保 apt 快取在同一層被清理
  ✓ 減小最終 image 大小

錯誤示範 (產生較大 image):
  RUN apt-get update           ← 層 1 (40 MB)
  RUN apt-get install -y ...   ← 層 2 (200 MB)
  RUN rm -rf /var/lib/apt/lists/*  ← 層 3 (0 MB，但前面的快取已存在)
  總計: 240 MB

正確示範 (減小 image):
  RUN apt-get update && \
      apt-get install -y ... && \
      rm -rf /var/lib/apt/lists/*  ← 單一層 (200 MB)
  總計: 200 MB
```

**第 6 行：WORKDIR /work**

```
WORKDIR = 設定工作目錄

類比: cd 命令，但會自動建立目錄

效果:
  1. 如果 /work 不存在，自動建立
  2. 後續的 RUN, CMD, COPY 等都在此目錄執行
  3. 容器啟動後，預設在此目錄

等價於:
  RUN mkdir -p /work
  RUN cd /work

但 WORKDIR 更好:
  ✓ 自動建立目錄
  ✓ 語意清晰
  ✓ 跨平台 (Windows/Linux 路徑差異由 Docker 處理)
```

**第 7 行：CMD ["qemu-system-arm", "--version"]**

```
CMD = 容器啟動時執行的預設命令

兩種格式:
  CMD ["executable", "param1", "param2"]   ← exec 形式 (推薦)
  CMD command param1 param2                ← shell 形式

exec 形式 vs shell 形式:

  exec 形式: CMD ["echo", "Hello"]
    ✓ 直接執行 echo
    ✓ 不會啟動 shell
    ✓ 效能較好
    ✓ 訊號處理正確 (SIGTERM, SIGKILL)

  shell 形式: CMD echo "Hello"
    ✗ 透過 /bin/sh -c 執行
    ✗ 多一個程序
    ✗ 訊號傳遞可能有問題

CMD vs ENTRYPOINT:

  CMD:
    • 可以被 docker run 的參數覆蓋
    • 適合預設行為

  ENTRYPOINT:
    • 不會被覆蓋 (除非用 --entrypoint)
    • 適合固定的執行檔

  範例:
    Dockerfile: CMD ["--version"]
                ENTRYPOINT ["qemu-system-arm"]

    $ docker run myimage           → qemu-system-arm --version
    $ docker run myimage --help    → qemu-system-arm --help
```

### 2.3 GDB 環境 Dockerfile

**Dockerfile.gdb**:

```dockerfile
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    gdb-multiarch \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /work
CMD ["gdb-multiarch", "--version"]
```

**與 QEMU Dockerfile 的差異**:

```
QEMU Dockerfile:
  安裝: qemu-system-arm    (ARM 模擬器)
  用途: 執行 ARM 程式

GDB Dockerfile:
  安裝: gdb-multiarch      (多架構除錯器)
  用途: 遠端除錯 ARM 程式

為什麼需要兩個?
  • 關注點分離 (Separation of Concerns)
  • QEMU 容器: 輕量級，只跑模擬器
  • GDB 容器: 包含除錯工具
  • 可以分別更新維護
```

### 2.4 Docker 層 (Layers) 概念

**每個指令建立一層**：

```
Dockerfile:                    Layers:
                              ┌─────────────────────┐
FROM debian:bookworm-slim  →  │ Layer 0: Debian OS  │ 80 MB
                              ├─────────────────────┤
RUN apt-get update &&      →  │ Layer 1: QEMU安裝   │ 120 MB
    apt-get install ...       ├─────────────────────┤
                              │ Layer 2: WORKDIR    │ 0 MB
WORKDIR /work              →  ├─────────────────────┤
                              │ Layer 3: CMD        │ 0 MB
CMD ["qemu-system-arm"]    →  └─────────────────────┘
                              總計: 200 MB

層的特性:
  ✓ 唯讀 (建立後不可修改)
  ✓ 可以被多個 Image 共享
  ✓ 快取機制 (加速建置)
```

**層的共享與快取**:

```
情境: 建立兩個相似的 Image

Image A (QEMU):
  FROM debian:bookworm-slim      ← Layer 0 (80 MB)
  RUN apt-get update             ← Layer 1 (40 MB)
  RUN apt-get install qemu       ← Layer 2 (120 MB)

Image B (GDB):
  FROM debian:bookworm-slim      ← Layer 0 (共享，0 MB)
  RUN apt-get update             ← Layer 1 (共享，0 MB)
  RUN apt-get install gdb        ← Layer 3 (新層，80 MB)

實際儲存:
  Layer 0: 80 MB  (兩個 Image 共享)
  Layer 1: 40 MB  (兩個 Image 共享)
  Layer 2: 120 MB (Image A 專用)
  Layer 3: 80 MB  (Image B 專用)
  ─────────────────────────────
  總計: 320 MB (而非 440 MB)

省下: 120 MB!
```

---

## 3. Docker 基本指令詳解

### 3.1 建置 Image

**docker build 命令**:

```bash
docker build -t cmsis-lm3s-qemu:latest -f Dockerfile .
```

**參數解析**:

```
docker build
  └─ 建置 Docker Image

-t cmsis-lm3s-qemu:latest
  └─ --tag (標籤)
     └─ cmsis-lm3s-qemu  ← Image 名稱
        └─ :latest       ← 標籤 (版本)

-f Dockerfile
  └─ --file (指定 Dockerfile)
     └─ Dockerfile  ← 檔案名稱
     (預設就是 Dockerfile，所以這個參數可省略)

.
└─ Build Context (建置上下文)
   └─ 當前目錄
   └─ Docker 會將此目錄的所有檔案發送給 Docker Daemon
```

**建置過程視覺化**:

```
$ docker build -t cmsis-lm3s-qemu:latest .

Step 1/4 : FROM debian:bookworm-slim
 ---> Pulling from library/debian
 ---> a1b2c3d4e5f6  ← 下載 base image
Successfully pulled debian:bookworm-slim

Step 2/4 : RUN apt-get update && apt-get install -y qemu-system-arm
 ---> Running in temp-container-xyz  ← 建立臨時容器
 ---> 執行 apt-get update
 ---> 執行 apt-get install
 ---> a7b8c9d0e1f2  ← 建立新層並提交

Step 3/4 : WORKDIR /work
 ---> Running in temp-container-abc
 ---> f3g4h5i6j7k8  ← 建立新層

Step 4/4 : CMD ["qemu-system-arm", "--version"]
 ---> Running in temp-container-def
 ---> k9l0m1n2o3p4  ← 最終 Image ID

Successfully built k9l0m1n2o3p4
Successfully tagged cmsis-lm3s-qemu:latest
```

**快取機制**:

```
第一次建置:
  Step 1/4 : FROM debian:bookworm-slim
   ---> Downloading... (3 分鐘)
  Step 2/4 : RUN apt-get update && apt-get install -y qemu
   ---> Executing... (5 分鐘)
  總時間: 8 分鐘

第二次建置 (沒有修改):
  Step 1/4 : FROM debian:bookworm-slim
   ---> Using cache ✓ (0.1 秒)
  Step 2/4 : RUN apt-get update && apt-get install -y qemu
   ---> Using cache ✓ (0.1 秒)
  總時間: 0.2 秒 (快 2400 倍!)

修改 Dockerfile 後 (加入新套件):
  Step 1/4 : FROM debian:bookworm-slim
   ---> Using cache ✓ (0.1 秒)
  Step 2/4 : RUN apt-get update && apt-get install -y qemu gcc
   ---> Cache invalidated, executing... (3 分鐘)
   ---> 之後的所有層都需要重建
  總時間: 3 分鐘
```

### 3.2 執行容器

**docker run 命令**:

```bash
docker run --rm \
    -v /home/sbplab/jiawei/qemu/CMSIS_LM3S:/work:ro \
    cmsis-lm3s-qemu:latest \
    qemu-system-arm --version
```

**參數詳解**:

```
docker run
  └─ 建立並啟動容器

--rm
  └─ Remove (移除)
  └─ 容器停止後自動刪除
  └─ 避免累積大量已停止的容器

-v /home/sbplab/jiawei/qemu/CMSIS_LM3S:/work:ro
  └─ --volume (掛載磁碟區)
     │
     ├─ /home/sbplab/jiawei/qemu/CMSIS_LM3S
     │  └─ Host (主機) 路徑
     │
     ├─ :
     │  └─ 分隔符號
     │
     ├─ /work
     │  └─ Container (容器) 路徑
     │
     └─ :ro
        └─ Read-Only (唯讀)
        └─ 容器無法修改 Host 檔案

cmsis-lm3s-qemu:latest
  └─ Image 名稱:標籤

qemu-system-arm --version
  └─ 覆蓋 CMD 的命令
  └─ 如果沒有這行，會執行 Dockerfile 中的 CMD
```

**Volume 掛載詳解**:

```
類比: USB 隨身碟

Host 電腦:                Container (隔離的房間):
┌─────────────────┐       ┌─────────────────┐
│ /home/user/     │       │ /work/          │
│  ├─ src/        │ ───→  │  ├─ src/        │ (只能讀取)
│  ├─ build/      │ ───→  │  ├─ build/      │ (只能讀取)
│  └─ README.md   │ ───→  │  └─ README.md   │ (只能讀取)
└─────────────────┘       └─────────────────┘
      實體檔案                   映射檔案
                          (ro = 唯讀，像是防寫開關)

好處:
  ✓ Host 修改檔案 → Container 立即看到
  ✓ 不需要重建 Image
  ✓ 開發效率高

:ro (Read-Only) 的用途:
  ✓ 防止容器意外修改 Host 檔案
  ✓ 安全性 (容器被入侵也無法破壞原始碼)
  ✓ 多個容器可同時讀取同一份檔案
```

**常用 docker run 參數**:

```bash
# 互動模式 (進入容器的 shell)
docker run -it debian:bookworm-slim /bin/bash

# 背景執行
docker run -d nginx

# 指定容器名稱
docker run --name my-qemu cmsis-lm3s-qemu:latest

# 埠號映射 (容器 80 → Host 8080)
docker run -p 8080:80 nginx

# 環境變數
docker run -e DEBUG=1 myapp

# 限制記憶體
docker run -m 512m myapp

# 限制 CPU
docker run --cpus="1.5" myapp

# 工作目錄
docker run -w /app myapp

# 覆蓋 ENTRYPOINT
docker run --entrypoint /bin/sh myapp
```

### 3.3 管理 Images

```bash
# 列出所有 images
docker images

# 輸出範例:
REPOSITORY          TAG       IMAGE ID       CREATED        SIZE
cmsis-lm3s-qemu     latest    k9l0m1n2o3p4   2 hours ago    200MB
debian              bookworm  a1b2c3d4e5f6   3 days ago     80MB

# 刪除 image
docker rmi cmsis-lm3s-qemu:latest

# 刪除所有未使用的 images
docker image prune

# 查看 image 詳細資訊
docker inspect cmsis-lm3s-qemu:latest

# 查看 image 歷史 (每一層)
docker history cmsis-lm3s-qemu:latest

# 儲存 image 為檔案
docker save -o qemu-image.tar cmsis-lm3s-qemu:latest

# 從檔案載入 image
docker load -i qemu-image.tar

# 標記 image (建立別名)
docker tag cmsis-lm3s-qemu:latest cmsis-lm3s-qemu:v1.0
```

### 3.4 管理 Containers

```bash
# 列出執行中的容器
docker ps

# 列出所有容器 (包括已停止)
docker ps -a

# 輸出範例:
CONTAINER ID   IMAGE            COMMAND                  STATUS
abc123def456   cmsis-lm3s-qemu  "qemu-system-arm..."    Up 5 minutes

# 停止容器
docker stop abc123def456

# 啟動已停止的容器
docker start abc123def456

# 重啟容器
docker restart abc123def456

# 刪除容器
docker rm abc123def456

# 強制刪除執行中的容器
docker rm -f abc123def456

# 刪除所有已停止的容器
docker container prune

# 查看容器日誌
docker logs abc123def456

# 實時追蹤日誌
docker logs -f abc123def456

# 進入執行中的容器
docker exec -it abc123def456 /bin/bash

# 查看容器內的程序
docker top abc123def456

# 查看容器資源使用情況
docker stats abc123def456

# 複製檔案 (Host → Container)
docker cp myfile.txt abc123def456:/work/

# 複製檔案 (Container → Host)
docker cp abc123def456:/work/output.txt ./
```

---

## 4. docker-compose 詳解

### 4.1 什麼是 docker-compose？

**docker-compose = 樂團指揮 🎼**

```
單一容器 (docker run):
  演奏家 A 獨奏
  ┌─────────┐
  │  小提琴 │
  └─────────┘

多容器 (docker-compose):
  整個交響樂團
  ┌─────────┬─────────┬─────────┬─────────┐
  │ 小提琴  │  大提琴 │  長笛   │  鋼琴   │
  └─────────┴─────────┴─────────┴─────────┘
       ↓         ↓         ↓         ↓
    QEMU      GDB      編譯器    資料庫

  指揮 (docker-compose.yml):
    • 定義所有樂器 (服務)
    • 協調合奏時機
    • 統一管理
```

**為什麼需要 docker-compose？**

```
問題：手動管理多個容器很麻煩

# 啟動 QEMU
docker run --rm -v $(pwd):/work:ro \
    cmsis-lm3s-qemu:latest \
    qemu-system-arm -M lm3s6965evb \
    -nographic -s -S \
    -kernel /work/examples/uart_hello_world/gcc/uart_hello_world.bin

# 啟動 GDB
docker run --rm -it -v $(pwd):/work:ro \
    --network host \
    cmsis-lm3s-gdb:latest \
    gdb-multiarch /work/examples/uart_hello_world/gcc/uart_hello_world.axf

# 需要記住兩個長命令！
# 需要手動協調啟動順序！
# 修改參數需要編輯兩處！

解決：docker-compose

$ docker-compose up
  → 自動啟動所有服務
  → 配置集中管理
  → 一個命令搞定！
```

### 4.2 專案 docker-compose.yml 解析

```yaml
version: '3'

services:
  qemu:
    image: cmsis-lm3s-qemu:latest
    volumes:
      - .:/work:ro
    working_dir: /work

  uart-hello:
    image: cmsis-lm3s-qemu:latest
    volumes:
      - .:/work:ro
    working_dir: /work/examples/uart_hello_world/gcc
    command: timeout 3 qemu-system-arm -M lm3s6965evb
             -nographic -kernel uart_hello_world.bin
```

**逐段解析**:

```yaml
version: '3'
```
```
版本宣告:
  • docker-compose 檔案格式版本
  • '3' = 最新穩定版本
  • 不同版本支援不同功能
```

```yaml
services:
```
```
服務定義區塊:
  • services = 容器的集合
  • 每個服務 = 一個容器 (或一組容器)
```

```yaml
  qemu:
    image: cmsis-lm3s-qemu:latest
    volumes:
      - .:/work:ro
    working_dir: /work
```
```
服務 1: qemu

  qemu:
    └─ 服務名稱 (自訂，用於內部網路通訊)

  image: cmsis-lm3s-qemu:latest
    └─ 使用的 Docker Image
    └─ 等同於 docker run 的 Image 參數

  volumes:
    - .:/work:ro
    └─ 掛載磁碟區
    └─ . = 當前目錄 (docker-compose.yml 所在目錄)
    └─ 等同於 -v $(pwd):/work:ro

  working_dir: /work
    └─ 設定工作目錄
    └─ 等同於 -w /work
```

```yaml
  uart-hello:
    image: cmsis-lm3s-qemu:latest
    volumes:
      - .:/work:ro
    working_dir: /work/examples/uart_hello_world/gcc
    command: timeout 3 qemu-system-arm -M lm3s6965evb
             -nographic -kernel uart_hello_world.bin
```
```
服務 2: uart-hello

  command: timeout 3 qemu-system-arm ...
    └─ 覆蓋 Dockerfile 的 CMD
    └─ 等同於 docker run 最後的命令參數

    timeout 3
      └─ 3 秒後強制結束 (避免無窮迴圈卡住)

    qemu-system-arm -M lm3s6965evb
      └─ 指定機器型號: LM3S6965 評估板

    -nographic
      └─ 不顯示圖形介面 (只用序列埠)

    -kernel uart_hello_world.bin
      └─ 載入核心映像檔
```

### 4.3 docker-compose 常用命令

```bash
# 啟動所有服務 (前景執行)
docker-compose up

# 啟動所有服務 (背景執行)
docker-compose up -d

# 啟動特定服務
docker-compose up uart-hello

# 執行一次性命令
docker-compose run qemu qemu-system-arm --version

# 查看服務狀態
docker-compose ps

# 查看服務日誌
docker-compose logs

# 實時追蹤日誌
docker-compose logs -f uart-hello

# 停止所有服務
docker-compose stop

# 停止並刪除容器
docker-compose down

# 停止並刪除容器、網路、volumes
docker-compose down -v

# 重啟服務
docker-compose restart

# 進入執行中的服務
docker-compose exec qemu /bin/bash

# 查看配置 (驗證 YAML 格式)
docker-compose config

# 建置 images (如果 YAML 中有 build)
docker-compose build
```

### 4.4 進階 docker-compose 功能

**服務依賴**:

```yaml
services:
  db:
    image: postgres:15

  web:
    image: myapp:latest
    depends_on:
      - db  # web 會等 db 啟動後才啟動
```

**環境變數**:

```yaml
services:
  app:
    image: myapp:latest
    environment:
      - DEBUG=1
      - DB_HOST=postgres
    env_file:
      - .env  # 從檔案載入環境變數
```

**埠號映射**:

```yaml
services:
  web:
    image: nginx
    ports:
      - "8080:80"  # Host:Container
      - "443:443"
```

**網路**:

```yaml
services:
  app1:
    networks:
      - frontend

  app2:
    networks:
      - backend

networks:
  frontend:
  backend:
```

---

## 5. 專案實戰應用

### 5.1 編譯 ARM 程式

```bash
# 方法 1: 使用 docker run
docker run --rm \
    -v $(pwd):/work \
    -w /work/examples/uart_hello_world \
    cmsis-lm3s-qemu:latest \
    make

# 方法 2: 使用 docker-compose
docker-compose run --rm qemu make -C examples/uart_hello_world

# 解析:
  --rm                    # 執行完畢後刪除容器
  qemu                    # 使用 qemu 服務
  make                    # 執行 make 命令
  -C examples/...         # make 參數: 切換到指定目錄
```

**完整工作流程**:

```bash
# 步驟 1: 建置 Docker Images
docker build -t cmsis-lm3s-qemu:latest -f Dockerfile .
docker build -t cmsis-lm3s-gdb:latest -f Dockerfile.gdb .

# 步驟 2: 編譯程式
docker run --rm -v $(pwd):/work \
    -w /work/examples/uart_hello_world \
    cmsis-lm3s-qemu:latest make

# 步驟 3: 執行程式
docker run --rm -v $(pwd):/work:ro \
    cmsis-lm3s-qemu:latest \
    bash -c "cd /work/examples/uart_hello_world/gcc && \
             timeout 3 qemu-system-arm -M lm3s6965evb \
                     -nographic -kernel uart_hello_world.bin"

# 預期輸出:
Hello, World!
```

### 5.2 除錯工作流程

**Terminal 1 (啟動 QEMU，等待 GDB 連線)**:

```bash
docker run --rm \
    -v $(pwd):/work:ro \
    -p 1234:1234 \
    cmsis-lm3s-qemu:latest \
    bash -c "cd /work/examples/uart_hello_world/gcc && \
             qemu-system-arm -M lm3s6965evb -nographic \
                     -kernel uart_hello_world.axf -s -S"

# 參數解析:
  -p 1234:1234    # 映射 GDB 埠號
  -s              # 在 :1234 開啟 GDB server
  -S              # 啟動時暫停，等待 GDB 連線
```

**Terminal 2 (啟動 GDB，連線到 QEMU)**:

```bash
docker run --rm -it \
    -v $(pwd):/work:ro \
    --network host \
    cmsis-lm3s-gdb:latest \
    bash -c "cd /work/examples/uart_hello_world/gcc && \
             gdb-multiarch uart_hello_world.axf"

# GDB 命令:
(gdb) target remote localhost:1234  # 連線到 QEMU
(gdb) break main                     # 設中斷點
(gdb) continue                       # 執行
(gdb) next                           # 單步執行
(gdb) print variable                 # 查看變數
```

### 5.3 建立自己的開發環境

**Dockerfile.dev (完整開發環境)**:

```dockerfile
FROM debian:bookworm-slim

# 安裝所有開發工具
RUN apt-get update && apt-get install -y \
    # 編譯器
    gcc-arm-none-eabi \
    # 建置工具
    make \
    cmake \
    # 除錯工具
    gdb-multiarch \
    # 模擬器
    qemu-system-arm \
    # 版本控制
    git \
    # 編輯器
    vim \
    nano \
    # 其他工具
    ca-certificates \
    wget \
    curl && \
    rm -rf /var/lib/apt/lists/*

# 設定工作目錄
WORKDIR /project

# 預設進入 bash
CMD ["/bin/bash"]
```

**使用範例**:

```bash
# 建置開發環境 Image
docker build -t arm-dev-env:latest -f Dockerfile.dev .

# 進入開發環境
docker run --rm -it \
    -v $(pwd):/project \
    arm-dev-env:latest

# 在容器內:
root@abc123:/project# make
root@abc123:/project# qemu-system-arm ...
root@abc123:/project# gdb-multiarch ...
```

---

## 6. 最佳實踐與技巧

### 6.1 減小 Image 大小

**技巧 1：使用精簡基底 Image**

```dockerfile
# 不佳 (200 MB)
FROM ubuntu:22.04

# 較好 (80 MB)
FROM debian:bookworm-slim

# 最佳 (5 MB，但可能有相容性問題)
FROM alpine:latest
```

**技巧 2：合併 RUN 指令**

```dockerfile
# 不佳 (產生 3 層，總計 240 MB)
RUN apt-get update
RUN apt-get install -y qemu-system-arm
RUN rm -rf /var/lib/apt/lists/*

# 較好 (產生 1 層，總計 200 MB)
RUN apt-get update && \
    apt-get install -y qemu-system-arm && \
    rm -rf /var/lib/apt/lists/*
```

**技巧 3：使用 .dockerignore**

```.dockerignore
# 排除不需要的檔案，加速建置
.git
.gitignore
*.md
node_modules
*.log
.DS_Store
```

**技巧 4：多階段建置 (Multi-stage Build)**

```dockerfile
# 階段 1: 建置
FROM gcc:11 AS builder
WORKDIR /build
COPY . .
RUN make

# 階段 2: 執行 (只複製必要檔案)
FROM debian:bookworm-slim
COPY --from=builder /build/output /app/
CMD ["/app/main"]

# 優點:
# • builder 階段的工具不會包含在最終 Image
# • 最終 Image 只有執行檔 + 最小依賴
# • 大小可減少 70-90%
```

### 6.2 安全性建議

```dockerfile
# 不要以 root 執行
RUN useradd -m myuser
USER myuser

# 只複製必要檔案
COPY --chown=myuser:myuser app/ /app/

# 使用特定版本 (避免 latest)
FROM debian:bookworm-slim  # ✓
FROM debian:latest         # ✗

# 定期更新套件
RUN apt-get update && apt-get upgrade -y

# 掃描漏洞
# $ docker scan cmsis-lm3s-qemu:latest
```

### 6.3 除錯技巧

```bash
# 進入 Image 的 shell (檢查檔案)
docker run --rm -it cmsis-lm3s-qemu:latest /bin/bash

# 查看建置歷史
docker history cmsis-lm3s-qemu:latest

# 查看某一層的變更
docker diff <container_id>

# 檢查 Dockerfile 語法
docker build --no-cache --progress=plain .

# 從特定層開始建置 (除錯用)
docker build --target builder .
```

---

## 7. 常見問題與解決

### 7.1 權限問題

**問題**: 容器內建立的檔案在 Host 無法刪除

```bash
# 容器內 (以 root 執行)
$ docker run -v $(pwd):/work myimage
root@container:/work# touch newfile
root@container:/work# exit

# Host 上 (一般使用者)
$ ls -l newfile
-rw-r--r-- 1 root root 0 Nov 16 10:00 newfile
$ rm newfile
rm: cannot remove 'newfile': Permission denied
```

**解決 1**: 使用相同 UID

```bash
docker run --user $(id -u):$(id -g) \
    -v $(pwd):/work myimage
```

**解決 2**: Dockerfile 建立相同 UID 使用者

```dockerfile
ARG UID=1000
ARG GID=1000

RUN groupadd -g ${GID} myuser && \
    useradd -u ${UID} -g ${GID} -m myuser

USER myuser
```

### 7.2 網路問題

**問題**: 容器無法連線到外部

```bash
# 檢查 DNS
docker run --rm alpine ping google.com

# 如果失敗，檢查 Docker DNS 設定
cat /etc/docker/daemon.json
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}

# 重啟 Docker
sudo systemctl restart docker
```

### 7.3 儲存空間問題

**問題**: Docker 佔用大量空間

```bash
# 查看空間使用
docker system df

# 清理未使用的資源
docker system prune

# 清理所有未使用的資源 (包括 volumes)
docker system prune -a --volumes

# 查看哪些 containers/images 佔用空間
docker ps -as
docker images
```

---

## 🎯 學習檢查點

完成本模組後，你應該能夠：

### 概念理解
- [ ] 解釋什麼是容器化
- [ ] 比較容器與虛擬機的差異
- [ ] 理解 Image 與 Container 的關係
- [ ] 知道 Docker 的分層架構

### Dockerfile 撰寫
- [ ] 會使用 FROM, RUN, WORKDIR, CMD
- [ ] 理解 Docker 層的概念
- [ ] 會優化 Dockerfile (減小大小、使用快取)
- [ ] 知道如何除錯 Dockerfile

### Docker 操作
- [ ] 會建置 Image (`docker build`)
- [ ] 會執行容器 (`docker run`)
- [ ] 會掛載 Volume (`-v`)
- [ ] 會管理 Images 和 Containers

### docker-compose
- [ ] 會撰寫 docker-compose.yml
- [ ] 理解服務 (services) 的概念
- [ ] 會使用 `docker-compose up/down`
- [ ] 知道如何定義多個服務

### 實戰應用
- [ ] 能夠建立嵌入式開發環境
- [ ] 會在容器內編譯 ARM 程式
- [ ] 會使用 Docker 進行除錯
- [ ] 能夠解決常見問題

---

## 🔗 下一步

恭喜你完成 Docker 容器技術的學習！

**接下來**:
- [模組 10：QEMU 模擬器](10-QEMU模擬器.md) - 學習如何使用 QEMU
- [模組 11：GDB 除錯器](11-GDB除錯器.md) - 學習遠端除錯

**進階主題**:
- Kubernetes (容器編排)
- Docker Swarm (叢集管理)
- CI/CD 整合 (GitLab CI, GitHub Actions)
- 容器安全性掃描

**實戰應用**:
- 建立完整的嵌入式開發環境
- 自動化測試流程
- 持續整合/持續部署
- 團隊協作開發

---

**版本**: 2.0 | **日期**: 2025-11-16 | **作者**: Claude Code Teaching Assistant
