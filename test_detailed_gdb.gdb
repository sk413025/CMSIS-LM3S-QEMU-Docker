# 詳細測試 GDB 功能
set pagination off
set confirm off

echo \n========================================\n
echo   測試 GDB 除錯功能\n
echo ========================================\n

# 連接
target remote localhost:1234
echo ✓ 成功連接到 QEMU\n

# 設定多個中斷點
echo \n--- 設定中斷點 ---\n
break main
break arm_fir_init_f32
break arm_fir_f32
info breakpoints

# 執行到 main
echo \n--- 執行到 main() ---\n
continue
info registers r0 r1 r2 r3

# 執行到 arm_fir_init_f32
echo \n--- 執行到 arm_fir_init_f32() ---\n
continue
info args
backtrace

# 執行到 arm_fir_f32
echo \n--- 執行到 arm_fir_f32() ---\n
continue
info args
backtrace

# 檢查記憶體
echo \n--- 檢查記憶體 ---\n
x/4x $sp
x/4x $pc

# 檢查暫存器
echo \n--- 暫存器狀態 ---\n
info registers

echo \n========================================\n
echo   所有測試完成！\n
echo ========================================\n

quit
