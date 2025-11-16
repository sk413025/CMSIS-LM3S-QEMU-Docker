#!/bin/bash
# CMSIS_LM3S 範例執行腳本
# 使用 Docker 執行編譯好的範例程式

set -e  # 遇到錯誤立即停止

# 顏色輸出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 專案根目錄
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_IMAGE="cmsis-lm3s-qemu:latest"

# 函數：顯示標題
print_header() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}======================================${NC}"
}

# 函數：顯示成功訊息
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# 函數：顯示警告訊息
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# 函數：顯示錯誤訊息
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# 檢查 Docker 是否安裝
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安裝或不在 PATH 中"
        echo "請先安裝 Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    print_success "Docker 已安裝"
}

# 建置 Docker image
build_image() {
    print_header "建置 Docker Image"

    if docker image inspect "$DOCKER_IMAGE" &> /dev/null; then
        print_warning "Docker image 已存在，是否重新建置？(y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_success "跳過建置，使用現有 image"
            return 0
        fi
    fi

    cd "$PROJECT_ROOT"
    docker build -t "$DOCKER_IMAGE" .
    print_success "Docker image 建置完成"
}

# 執行 UART Hello World 範例
run_uart_example() {
    print_header "執行 UART Hello World 範例"

    local bin_file="$PROJECT_ROOT/examples/uart_hello_world/gcc/uart_hello_world.bin"

    if [[ ! -f "$bin_file" ]]; then
        print_error "找不到 $bin_file"
        print_warning "請先執行 'make' 編譯專案"
        return 1
    fi

    echo -e "${YELLOW}執行中...${NC}"
    docker run --rm \
        -v "$PROJECT_ROOT:/work:ro" \
        -w /work/examples/uart_hello_world/gcc \
        "$DOCKER_IMAGE" \
        timeout 3 qemu-system-arm \
            -M lm3s6965evb \
            -nographic \
            -kernel uart_hello_world.bin 2>&1 || true

    print_success "UART 範例執行完成"
}

# 執行 FIR 濾波器範例
run_fir_example() {
    print_header "執行 FIR 濾波器範例"

    local bin_file="$PROJECT_ROOT/examples/arm_fir_example/gcc/arm_fir_example_f32.bin"

    if [[ ! -f "$bin_file" ]]; then
        print_error "找不到 $bin_file"
        print_warning "請先執行 'make' 編譯專案"
        return 1
    fi

    echo -e "${YELLOW}執行中...${NC}"
    docker run --rm \
        -v "$PROJECT_ROOT:/work:ro" \
        -w /work/examples/arm_fir_example/gcc \
        "$DOCKER_IMAGE" \
        timeout 3 qemu-system-arm \
            -M lm3s6965evb \
            -nographic \
            -kernel arm_fir_example_f32.bin 2>&1 || true

    print_success "FIR 濾波器範例執行完成"
}

# 顯示使用說明
show_usage() {
    cat << EOF
用法: $0 [選項]

選項:
    build       建置 Docker image
    uart        執行 UART Hello World 範例
    fir         執行 FIR 濾波器範例
    all         執行所有範例
    clean       清理 Docker image
    help        顯示此說明

範例:
    $0 build          # 建置 Docker image
    $0 uart           # 執行 UART 範例
    $0 all            # 執行所有範例
    $0 clean          # 清理 Docker image

EOF
}

# 清理 Docker image
clean_image() {
    print_header "清理 Docker Image"

    if docker image inspect "$DOCKER_IMAGE" &> /dev/null; then
        docker rmi "$DOCKER_IMAGE"
        print_success "Docker image 已刪除"
    else
        print_warning "Docker image 不存在，無需清理"
    fi
}

# 主程式
main() {
    check_docker

    case "${1:-}" in
        build)
            build_image
            ;;
        uart)
            build_image
            run_uart_example
            ;;
        fir)
            build_image
            run_fir_example
            ;;
        all)
            build_image
            run_uart_example
            echo ""
            run_fir_example
            ;;
        clean)
            clean_image
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "無效的選項: ${1:-}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
