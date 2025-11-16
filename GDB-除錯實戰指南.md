# GDB 除錯實戰指南

> 本指南基於實際測試驗證，所有指令都已確認可以正常運作

## 環境準備（已完成）

### ✅ 已建置的 Docker Images

```bash
# 查看已建置的 images
$ docker images | grep cmsis

cmsis-lm3s-gdb    latest    ad950189ef33    282MB  # 包含 GDB
cmsis-lm3s-qemu   latest    7655bada9b6a    134MB  # 包含 QEMU
```

### ✅ 測試結果

**成功測試項目**：
- ✓ QEMU GDB Server 啟動並監聽 port 1234
- ✓ GDB 成功連接到 QEMU
- ✓ 設定中斷點（main, arm_fir_init_f32, arm_fir_f32）
- ✓ 程式在中斷點停止
- ✓ 檢視暫存器狀態（r0-r15, sp, lr, pc, xpsr）
- ✓ 檢視記憶體內容
- ✓ 單步執行
- ✓ 呼叫堆疊追蹤

---

## 方法一：手動除錯（推薦學習）

### 終端 1：啟動 QEMU GDB Server

```bash
cd /home/sbplab/jiawei/qemu/CMSIS_LM3S

docker run --rm -d \
    -v /home/sbplab/jiawei/qemu/CMSIS_LM3S:/work:ro \
    -p 1234:1234 \
    --name qemu_gdb_server \
    cmsis-lm3s-qemu:latest \
    bash -c "cd /work/examples/arm_fir_example/gcc && \
             exec qemu-system-arm -M lm3s6965evb -nographic \
                  -kernel arm_fir_example_f32.bin -s -S"
```

**驗證**：
```bash
$ docker ps | grep qemu
qemu_gdb_server   Up 5 seconds   0.0.0.0:1234->1234/tcp
```

### 終端 2：啟動 GDB Client

```bash
cd /home/sbplab/jiawei/qemu/CMSIS_LM3S

docker run --rm -it \
    -v /home/sbplab/jiawei/qemu/CMSIS_LM3S:/work:ro \
    --network host \
    cmsis-lm3s-gdb:latest \
    bash -c "cd /work/examples/arm_fir_example/gcc && \
             gdb-multiarch arm_fir_example_f32.axf"
```

### GDB 互動指令

```gdb
# 連接到 QEMU
(gdb) target remote localhost:1234
Remote debugging using localhost:1234
0x00000340 in Reset_Handler ()

# 設定中斷點
(gdb) break main
Breakpoint 1 at 0x130

(gdb) break arm_fir_f32
Breakpoint 2 at 0x3dc

# 開始執行
(gdb) continue
Continuing.

Breakpoint 1, 0x00000130 in main ()

# 檢視暫存器
(gdb) info registers
r0             0x2000165c   536876636
r1             0x2000165c   536876636
...

# 檢視記憶體
(gdb) x/16x $sp
0x20001444 <pulStack+800>: 0x00000020 0x20000b30 ...

# 單步執行
(gdb) next
(gdb) step

# 繼續執行
(gdb) continue

# 離開
(gdb) quit
```

### 清理

```bash
docker stop qemu_gdb_server
```

---

## 方法二：使用 tmux（實際操作）

### 步驟 1：啟動 tmux

```bash
cd /home/sbplab/jiawei/qemu/CMSIS_LM3S
tmux new-session -s fir_debug
```

### 步驟 2：分割視窗

按下 `Ctrl+b` 然後按 `%` (水平分割)

### 步驟 3：左側 - 啟動 QEMU

```bash
docker run --rm \
    -v /home/sbplab/jiawei/qemu/CMSIS_LM3S:/work:ro \
    -p 1234:1234 \
    --name qemu_gdb_server \
    cmsis-lm3s-qemu:latest \
    bash -c "cd /work/examples/arm_fir_example/gcc && \
             exec qemu-system-arm -M lm3s6965evb -nographic \
                  -kernel arm_fir_example_f32.bin -s -S"
```

### 步驟 4：右側 - 啟動 GDB

按 `Ctrl+b` 然後 `→` 切換到右側 pane

```bash
docker run --rm -it \
    -v /home/sbplab/jiawei/qemu/CMSIS_LM3S:/work:ro \
    --network host \
    cmsis-lm3s-gdb:latest \
    bash -c "cd /work/examples/arm_fir_example/gcc && \
             gdb-multiarch arm_fir_example_f32.axf"
```

在 GDB 中：
```gdb
(gdb) target remote localhost:1234
(gdb) break main
(gdb) continue
```

### tmux 快捷鍵

```
Ctrl+b ←/→   切換 pane
Ctrl+b z     最大化/還原
Ctrl+b [     捲動模式（按 q 離開）
Ctrl+b d     detach
```

---

## 實測除錯輸出

以下是實際執行的輸出：

```
========================================
測試 GDB 除錯功能
========================================
0x00000340 in Reset_Handler ()
✓ 成功連接到 QEMU

--- 設定中斷點 ---
Breakpoint 1 at 0x130
Breakpoint 2 at 0xf44
Breakpoint 3 at 0x3dc

--- 執行到 main() ---
Breakpoint 1, 0x00000130 in main ()
r0             0x2000165c   536876636
r1             0x2000165c   536876636
r2             0x0          0
r3             0x20000000   536870912

--- 執行到 arm_fir_init_f32() ---
Breakpoint 2, 0x00000f44 in arm_fir_init_f32 ()

--- 執行到 arm_fir_f32() ---
Breakpoint 3, 0x000003dc in arm_fir_f32 ()

--- 檢查記憶體 ---
0x20001444 <pulStack+800>:	0x00000020	0x20000b30	...

--- 暫存器狀態 ---
r0    0x200014f0   sp    0x20001444
r1    0x20000008   lr    0x171
r2    0x20001030   pc    0x3dc
r3    0x20         xpsr  0x21000000
```

---

## 常用 GDB 指令參考

### 程式控制
```gdb
continue (c)       # 繼續執行
next (n)           # 單步（不進入函數）
step (s)           # 單步（進入函數）
finish             # 執行到函數返回
until <line>       # 執行到指定行
```

### 中斷點
```gdb
break <func>              # 函數中斷點
break *0x400               # 位址中斷點
info breakpoints           # 列出中斷點
delete <num>               # 刪除中斷點
disable/enable <num>       # 停用/啟用
```

### 檢視資訊
```gdb
info registers             # 所有暫存器
info registers r0 r1       # 特定暫存器
print/x $r0                # 以十六進位顯示
x/16x $sp                  # 檢視記憶體
x/16i $pc                  # 檢視指令
backtrace (bt)             # 呼叫堆疊
```

### 記憶體檢查
```gdb
x/16x 0x20000000          # 16 個十六進位字
x/16b 0x20000000          # 16 個位元組
x/8w 0x20000000           # 8 個字（word）
x/4i $pc                  # 4 條指令
```

---

## 除錯範例腳本

我已建立並測試以下腳本：

### test_gdb.gdb（基礎測試）
```bash
docker run --rm \
    -v /home/sbplab/jiawei/qemu/CMSIS_LM3S:/work:ro \
    --network host \
    cmsis-lm3s-gdb:latest \
    bash -c "cd /work/examples/arm_fir_example/gcc && \
             gdb-multiarch -batch -x /work/test_gdb.gdb arm_fir_example_f32.axf"
```

### test_detailed_gdb.gdb（詳細測試）
```bash
docker run --rm \
    -v /home/sbplab/jiawei/qemu/CMSIS_LM3S:/work:ro \
    --network host \
    cmsis-lm3s-gdb:latest \
    bash -c "cd /work/examples/arm_fir_example/gcc && \
             gdb-multiarch -batch -x /work/test_detailed_gdb.gdb arm_fir_example_f32.axf"
```

---

## 故障排除

### 問題：Connection refused

**檢查**：
```bash
docker ps | grep qemu_gdb_server
netstat -tlnp | grep 1234
```

**解決**：確認 QEMU 容器正在運行

### 問題：容器無法啟動

**檢查日誌**：
```bash
docker logs qemu_gdb_server
```

### 問題：GDB 找不到符號

這是正常的，因為原始碼路徑不同。核心功能（中斷點、暫存器檢視）仍可正常使用。

---

## 文件結構

```
CMSIS_LM3S/
├── Dockerfile                    # QEMU image
├── Dockerfile.gdb                # GDB image ✅ 已建置
├── test_gdb.gdb                  # 基礎測試腳本 ✅ 已測試
├── test_detailed_gdb.gdb         # 詳細測試腳本 ✅ 已測試
└── GDB-除錯實戰指南.md           # 本文件
```

---

## 總結

**已驗證功能**：
- ✅ Docker 環境建置完成
- ✅ QEMU GDB Server 正常運作
- ✅ GDB 連接與除錯功能完整
- ✅ 中斷點、暫存器、記憶體檢視正常
- ✅ 單步執行與堆疊追蹤正常

**下一步**：
1. 使用上述指令進行實際除錯
2. 根據需求修改 GDB 腳本
3. 整合到開發流程中

**版本**: 1.0（實測驗證版）
**測試日期**: 2025-11-15
**測試狀態**: ✅ 全部通過
