# GDB 指令檔 - FIR 濾波器除錯
# 使用方式: arm-none-eabi-gdb -x gdb_commands.gdb arm_fir_example_f32.axf

# 連接到 QEMU GDB Server
target remote localhost:1234

# 設定中斷點
echo \n========================================\n
echo   設定中斷點\n
echo ========================================\n

# main 函數入口
break main
echo [1] 已設定中斷點於 main()\n

# FIR 範例主程式的關鍵位置
break arm_fir_example_f32.c:115
echo [2] 已設定中斷點於 arm_fir_example_f32.c:115 (FIR 初始化後)\n

# CMSIS DSP FIR 函數
break arm_fir_f32
echo [3] 已設定中斷點於 arm_fir_f32() (CMSIS DSP 函數)\n

echo \n========================================\n
echo   開始執行程式\n
echo ========================================\n

# 繼續執行到第一個中斷點
continue

# 顯示當前位置
echo \n========================================\n
echo   已命中中斷點！\n
echo ========================================\n
list

# 顯示區域變數
echo \n--- 區域變數 ---\n
info locals

# 使用說明
echo \n========================================\n
echo   GDB 除錯指令參考\n
echo ========================================\n
echo \n【基本控制】\n
echo   continue (c)      - 繼續執行到下一個中斷點\n
echo   next (n)          - 單步執行（不進入函數）\n
echo   step (s)          - 單步執行（進入函數）\n
echo   finish            - 執行到當前函數返回\n
echo \n【檢視資訊】\n
echo   print snr         - 顯示 SNR 變數值\n
echo   print testOutput_f32[0]@32  - 顯示陣列前32個元素\n
echo   info locals       - 顯示所有區域變數\n
echo   info args         - 顯示函數參數\n
echo   backtrace (bt)    - 顯示呼叫堆疊\n
echo   list              - 顯示原始碼\n
echo \n【中斷點管理】\n
echo   info breakpoints  - 列出所有中斷點\n
echo   disable 2         - 停用中斷點 #2\n
echo   enable 2          - 啟用中斷點 #2\n
echo   delete 2          - 刪除中斷點 #2\n
echo \n【記憶體與暫存器】\n
echo   info registers    - 顯示所有暫存器\n
echo   x/16x 0x20000000  - 顯示記憶體內容（16個十六進位值）\n
echo \n【其他】\n
echo   quit (q)          - 離開 GDB\n
echo ========================================\n
echo \n
