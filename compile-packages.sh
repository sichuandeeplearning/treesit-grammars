#!/bin/bash

# Tree-sitter 语法包编译脚本
# 从源码tar.gz包编译生成.so文件

# set -e  # 注释掉，避免编译失败时退出脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_PACKAGES_DIR="$SCRIPT_DIR/packages"
COMPILED_DIR="$SCRIPT_DIR/packages/compiled"
TEMP_BUILD_DIR=$(mktemp -d)

echo "🚀 Tree-sitter语法包编译工具"
echo "================================"
echo "📁 源码包目录: $SOURCE_PACKAGES_DIR"
echo "📁 编译输出目录: $COMPILED_DIR"
echo "🔧 临时构建目录: $TEMP_BUILD_DIR"
echo ""

# 创建编译输出目录
mkdir -p "$COMPILED_DIR"

# 清理函数
cleanup() {
    echo "🧹 清理临时文件..."
    rm -rf "$TEMP_BUILD_DIR"
}
trap cleanup EXIT

# 检查必要工具
check_dependencies() {
    local missing_tools=()
    
    if ! command -v gcc &> /dev/null && ! command -v clang &> /dev/null; then
        missing_tools+=("gcc 或 clang")
    fi
    
    if ! command -v make &> /dev/null; then
        missing_tools+=("make")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "❌ 缺少必要工具: ${missing_tools[*]}"
        echo "💡 请安装缺少的工具后重试"
        echo ""
        echo "Ubuntu/Debian 安装命令:"
        echo "  sudo apt update && sudo apt install build-essential"
        echo ""
        echo "macOS 安装命令:"
        echo "  xcode-select --install"
        exit 1
    fi
}

# 编译单个语言包
compile_language() {
    local lang="$1"
    local source_package="$SOURCE_PACKAGES_DIR/${lang}.tar.gz"
    local so_file="$COMPILED_DIR/libtree-sitter-${lang}.so"
    
    if [[ ! -f "$source_package" ]]; then
        echo "❌ 未找到源码包: $source_package"
        return 1
    fi
    
    # 检查.so文件是否已存在
    if [[ -f "$so_file" ]]; then
        echo "⏩ $lang: .so文件已存在，跳过编译"
        return 0
    fi
    
    echo "🔨 编译 $lang (从 $source_package)..."
    
    local lang_build_dir="$TEMP_BUILD_DIR/$lang"
    mkdir -p "$lang_build_dir"
    
    # 解压源码包
    echo "   📦 解压源码包..."
    if ! tar -xzf "$source_package" -C "$lang_build_dir" --strip-components=1 2>/dev/null; then
        echo "   ❌ 解压失败"
        return 1
    fi
    
    cd "$lang_build_dir"
    
    # 特殊处理typescript/tsx (需要进入子目录)
    if [[ "$lang" == "tsx" ]]; then
        if [[ -d "tsx" ]]; then
            cd "tsx"
        else
            echo "   ❌ 未找到tsx子目录"
            return 1
        fi
    elif [[ "$lang" == "typescript" ]]; then
        if [[ -d "typescript" ]]; then
            cd "typescript"
        else
            echo "   ❌ 未找到typescript子目录"
            return 1
        fi
    fi
    
    # 编译语法
    echo "   🔨 编译语法..."
    local temp_so_file="libtree-sitter-${lang}.so"
    
    # 尝试不同的编译方法
    local compiled=false
    
    # 方法1: 使用Makefile
    if [[ -f "Makefile" ]] && ! $compiled; then
        echo "   📋 使用Makefile编译..."
        if make &>/dev/null; then
            # 查找生成的.so文件
            local built_so=$(find . -name "*.so" | head -1)
            if [[ -n "$built_so" ]]; then
                if [[ "$built_so" != "./$temp_so_file" ]]; then
                    cp "$built_so" "$temp_so_file"
                fi
                compiled=true
            fi
        fi
    fi
    
    # 方法2: 手动编译
    if ! $compiled; then
        echo "   🔧 手动编译..."
        local src_files=$(find src -name "*.c" 2>/dev/null | tr '\n' ' ')
        if [[ -n "$src_files" ]]; then
            local cc="gcc"
            if command -v clang &> /dev/null; then
                cc="clang"
            fi
            
            if $cc -shared -fPIC -O2 $src_files -o "$temp_so_file" &>/dev/null; then
                compiled=true
            fi
        fi
    fi
    
    if ! $compiled; then
        echo "   ❌ 编译失败"
        return 1
    fi
    
    # 验证.so文件
    if [[ ! -f "$temp_so_file" ]]; then
        echo "   ❌ 未找到编译后的.so文件"
        return 1
    fi
    
    # 安装.so文件到目标目录
    echo "   📦 安装.so文件..."
    if ! cp "$temp_so_file" "$so_file"; then
        echo "   ❌ 安装.so文件失败"
        return 1
    fi
    
    echo "   ✅ $lang 编译成功: $so_file"
    return 0
}

# 编译所有可用的源码包
compile_all_packages() {
    local success_count=0
    local fail_count=0
    
    echo "🔄 开始编译所有可用的源码包..."
    echo ""
    
    # 查找所有源码包
    local source_packages=($(ls "$SOURCE_PACKAGES_DIR"/*.tar.gz 2>/dev/null | xargs -n1 basename | sed 's/\.tar\.gz$//' | sort))
    
    if [[ ${#source_packages[@]} -eq 0 ]]; then
        echo "❌ 未找到任何源码包"
        echo "💡 请先运行 ./download-sources.sh 下载源码包"
        return 1
    fi
    
    echo "📋 发现 ${#source_packages[@]} 个源码包: ${source_packages[*]}"
    echo ""
    
    for lang in "${source_packages[@]}"; do
        if compile_language "$lang"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
        echo ""
    done
    
    echo "📊 编译统计:"
    echo "   ✅ 成功: $success_count"
    echo "   ❌ 失败: $fail_count"
}

# 编译指定语言包
compile_specific_packages() {
    local languages=("$@")
    local success_count=0
    local fail_count=0
    
    echo "🔄 编译指定语言包: ${languages[*]}"
    echo ""
    
    for lang in "${languages[@]}"; do
        if compile_language "$lang"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
        echo ""
    done
    
    echo "📊 编译统计:"
    echo "   ✅ 成功: $success_count"
    echo "   ❌ 失败: $fail_count"
}

# 列出可用的源码包
list_available_packages() {
    echo "📋 可用的源码包:"
    echo ""
    
    local source_packages=($(ls "$SOURCE_PACKAGES_DIR"/*.tar.gz 2>/dev/null | xargs -n1 basename | sed 's/\.tar\.gz$//' | sort))
    
    if [[ ${#source_packages[@]} -eq 0 ]]; then
        echo "   ❌ 未找到任何源码包"
        echo "   💡 请先运行 ./download-sources.sh 下载源码包"
        return
    fi
    
    for lang in "${source_packages[@]}"; do
        local source_package="$SOURCE_PACKAGES_DIR/${lang}.tar.gz"
        local so_file="$COMPILED_DIR/libtree-sitter-${lang}.so"
        local source_status="✅"
        local compiled_status="❌"
        
        if [[ -f "$so_file" ]]; then
            compiled_status="✅"
        fi
        
        printf "   %-12s | 源码: %s | .so: %s\n" "$lang" "$source_status" "$compiled_status"
    done
    
    echo ""
    echo "说明: ✅=存在, ❌=不存在"
}

# 清理编译的.so文件
clean_compiled_packages() {
    echo "🧹 清理已编译的.so文件..."
    rm -rf "$COMPILED_DIR"/libtree-sitter-*.so 2>/dev/null || true
    echo "✅ 清理完成"
}

# 验证编译的.so文件
verify_compiled_packages() {
    echo "🔍 验证编译的.so文件..."
    local valid_count=0
    local invalid_count=0
    
    for so_file in "$COMPILED_DIR"/libtree-sitter-*.so; do
        if [[ -f "$so_file" ]]; then
            if file "$so_file" | grep -q "shared object"; then
                echo "   ✅ $(basename "$so_file"): 有效的共享库"
                ((valid_count++))
            else
                echo "   ❌ $(basename "$so_file"): 无效的文件"
                ((invalid_count++))
            fi
        fi
    done
    
    if [[ $valid_count -eq 0 && $invalid_count -eq 0 ]]; then
        echo "   ℹ️  未找到任何.so文件"
    fi
    
    echo ""
    echo "📊 验证结果:"
    echo "   ✅ 有效: $valid_count"
    echo "   ❌ 无效: $invalid_count"
}

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项] [语言...]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -l, --list     列出可用的源码包"
    echo "  -a, --all      编译所有可用的源码包 (默认)"
    echo "  -c, --clean    清理编译包目录"
    echo "  -v, --verify   验证编译包"
    echo "  -d, --deps     检查依赖工具"
    echo ""
    echo "示例:"
    echo "  $0                    # 编译所有可用的源码包"
    echo "  $0 python javascript # 只编译python和javascript"
    echo "  $0 --list            # 列出可用的源码包"
    echo "  $0 --clean           # 清理编译目录"
    echo "  $0 --verify          # 验证编译包"
    echo "  $0 --deps            # 检查依赖工具"
    echo ""
    echo "注意:"
    echo "  - 需要先运行 ./download-sources.sh 下载源码包"
    echo "  - 编译后的.so文件将保存到 packages/compiled/ 目录"
    echo "  - .so文件可以配合Emacs treesit配置使用"
}

# 主函数
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            ;;
        -l|--list)
            list_available_packages
            ;;
        -a|--all)
            check_dependencies
            compile_all_packages
            ;;
        -c|--clean)
            clean_compiled_packages
            ;;
        -v|--verify)
            verify_compiled_packages
            ;;
        -d|--deps)
            check_dependencies
            echo "✅ 所有依赖工具已安装"
            ;;
        "")
            # 默认编译所有包
            check_dependencies
            compile_all_packages
            ;;
        *)
            # 编译指定语言
            check_dependencies
            compile_specific_packages "$@"
            ;;
    esac
    
    echo ""
    echo "🎉 操作完成！"
    echo "💡 使用 'ls -lah $COMPILED_DIR' 查看编译的.so文件"
    echo "💡 .so文件保存在 packages/compiled/ 目录"
}

# 运行主函数
main "$@"
