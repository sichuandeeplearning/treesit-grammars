#!/bin/bash

# Tree-sitter 官方源码包下载脚本
# 从GitHub官方仓库下载各语言的源码tar.gz包

# set -e  # 注释掉，避免在下载失败时退出脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$SCRIPT_DIR/packages"

echo "🚀 Tree-sitter 官方源码包下载工具"
echo "================================"
echo "📁 下载目录: $PACKAGES_DIR"
echo ""

# 创建packages目录
mkdir -p "$PACKAGES_DIR"

# 官方语言仓库映射：语言名 -> GitHub仓库
declare -A LANGUAGE_REPOS=(
    ["c"]="tree-sitter/tree-sitter-c"
    ["cpp"]="tree-sitter/tree-sitter-cpp"
    ["python"]="tree-sitter/tree-sitter-python"
    ["java"]="tree-sitter/tree-sitter-java"
    ["javascript"]="tree-sitter/tree-sitter-javascript"
    ["typescript"]="tree-sitter/tree-sitter-typescript"
    ["tsx"]="tree-sitter/tree-sitter-typescript"
    ["json"]="tree-sitter/tree-sitter-json"
    ["css"]="tree-sitter/tree-sitter-css"
    ["html"]="tree-sitter/tree-sitter-html"
    ["bash"]="tree-sitter/tree-sitter-bash"
    ["cmake"]="uyha/tree-sitter-cmake"
    ["dockerfile"]="camdencheek/tree-sitter-dockerfile"
    ["rust"]="tree-sitter/tree-sitter-rust"
    ["go"]="tree-sitter/tree-sitter-go"
    ["elisp"]="Wilfred/tree-sitter-elisp"
)

# 检查curl是否可用
if ! command -v curl &> /dev/null; then
    echo "❌ 错误: 需要curl命令来下载文件"
    echo "💡 请安装curl: sudo apt install curl"
    exit 1
fi

# 下载单个语言的源码包
download_language_source() {
    local lang="$1"
    local repo="${LANGUAGE_REPOS[$lang]}"
    local package_file="$PACKAGES_DIR/${lang}.tar.gz"
    
    if [[ -z "$repo" ]]; then
        echo "❌ 不支持的语言: $lang"
        return 1
    fi
    
    # 检查本地是否已存在
    if [[ -f "$package_file" ]]; then
        echo "⏩ $lang: 源码包已存在，跳过下载"
        return 0
    fi
    
    echo "📦 下载 $lang 源码包 (从 $repo)..."
    
    # 从GitHub下载最新的源码tar.gz包
    local download_url="https://github.com/$repo/archive/refs/heads/master.tar.gz"
    
    echo "   🔗 下载地址: $download_url"
    
    if curl -L -f -s -o "$package_file" "$download_url"; then
        echo "   ✅ $lang 源码包下载成功"
        return 0
    else
        echo "   ❌ $lang 源码包下载失败"
        rm -f "$package_file"
        return 1
    fi
}

# 下载所有语言的源码包
download_all_sources() {
    local success_count=0
    local fail_count=0
    
    echo "🔄 开始下载所有语言源码包..."
    echo ""
    
    for lang in $(printf '%s\n' "${!LANGUAGE_REPOS[@]}" | sort); do
        if download_language_source "$lang"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done
    
    echo ""
    echo "📊 下载统计:"
    echo "   ✅ 成功: $success_count"
    echo "   ❌ 失败: $fail_count"
}

# 下载指定语言的源码包
download_specific_sources() {
    local languages=("$@")
    local success_count=0
    local fail_count=0
    
    echo "🔄 下载指定语言源码包: ${languages[*]}"
    echo ""
    
    for lang in "${languages[@]}"; do
        if download_language_source "$lang"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done
    
    echo ""
    echo "📊 下载统计:"
    echo "   ✅ 成功: $success_count"
    echo "   ❌ 失败: $fail_count"
}

# 列出支持的语言
list_supported_languages() {
    echo "📋 支持的语言列表:"
    echo ""
    for lang in $(printf '%s\n' "${!LANGUAGE_REPOS[@]}" | sort); do
        local repo="${LANGUAGE_REPOS[$lang]}"
        local package_file="$PACKAGES_DIR/${lang}.tar.gz"
        local status="❌"
        
        if [[ -f "$package_file" ]]; then
            status="✅"
        fi
        
        printf "   %s %-12s -> %s\n" "$status" "$lang" "$repo"
    done
    echo ""
    echo "说明: ✅=已下载, ❌=未下载"
}

# 清理packages目录
clean_packages() {
    echo "🧹 清理packages目录..."
    rm -rf "$PACKAGES_DIR"/*.tar.gz 2>/dev/null || true
    echo "✅ 清理完成"
}

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项] [语言...]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -l, --list     列出支持的语言"
    echo "  -a, --all      下载所有语言源码包 (默认)"
    echo "  -c, --clean    清理packages目录"
    echo ""
    echo "示例:"
    echo "  $0                    # 下载所有语言源码包"
    echo "  $0 python javascript # 只下载python和javascript源码包"
    echo "  $0 --list            # 列出支持的语言"
    echo "  $0 --clean           # 清理下载目录"
}

# 主函数
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            ;;
        -l|--list)
            list_supported_languages
            ;;
        -a|--all)
            download_all_sources
            ;;
        -c|--clean)
            clean_packages
            ;;
        "")
            # 默认下载所有源码包
            download_all_sources
            ;;
        *)
            # 下载指定语言源码包
            download_specific_sources "$@"
            ;;
    esac
    
    echo ""
    echo "🎉 操作完成！"
    echo "💡 使用 'ls -lah $PACKAGES_DIR' 查看下载的源码包"
}

# 运行主函数
main "$@"
