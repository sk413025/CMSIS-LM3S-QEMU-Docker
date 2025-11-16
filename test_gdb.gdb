# 測試 GDB 連接腳本
set pagination off
set confirm off

echo \n=== 連接到 QEMU GDB Server ===\n
target remote localhost:1234

echo \n=== 設定中斷點 ===\n
break main
info breakpoints

echo \n=== 繼續執行到 main ===\n
continue

echo \n=== 顯示當前位置 ===\n
where
list

echo \n=== 顯示區域變數 ===\n
info locals

echo \n=== 單步執行 3 步 ===\n
next
next
next

echo \n=== 再次顯示位置 ===\n
where

echo \n=== GDB 測試成功！ ===\n
quit
