#!/bin/bash

# Tree-sitter 语法包生成脚本
# 用于从现有的Tree-sitter安装中生成tar.gz包

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$SCRIPT_DIR/packages"
SYSTEM_TREESIT_DIR="$HOME/.emacs.d/tree-sitter"

echo "🚀 Tree-sitter语法包生成工具"
echo "================================"

# 创建packages目录
mkdir -p "$PACKAGES_DIR"

# 支持的语言列表
LANGUAGES=(
    "c"
    "cpp" 
    "python"
    "java"
    "javascript"
    "typescript"
    "tsx"
    "json"
    "css"
    "html"
    "yaml"
    "bash"
    "cmake"
    "dockerfile"
    "toml"
    "rust"
    "go"
    "elisp"
)

generate_package() {
    local lang="$1"
    local so_file="$SYSTEM_TREESIT_DIR/libtree-sitter-${lang}.so"
    local package_file="$PACKAGES_DIR/${lang}.tar.gz"
    
    if [[ -f "$so_file" ]]; then
        echo "📦 生成 $lang 包..."
        
        # 创建临时目录
        local temp_dir=$(mktemp -d)
        
        # 复制.so文件到临时目录
        cp "$so_file" "$temp_dir/"
        
        # 创建tar.gz包
        (cd "$temp_dir" && tar -czf "$package_file" "libtree-sitter-${lang}.so")
        
        # 清理临时目录
        rm -rf "$temp_dir"
        
        echo "✅ $lang 包生成完成: $package_file"
    else
        echo "⚠️  跳过 $lang (未找到: $so_file)"
    fi
}

# 检查系统Tree-sitter目录
if [[ ! -d "$SYSTEM_TREESIT_DIR" ]]; then
    echo "❌ 未找到Tree-sitter安装目录: $SYSTEM_TREESIT_DIR"
    echo "💡 请先使用标准方式安装Tree-sitter语法，然后运行此脚本"
    exit 1
fi

echo "🔍 在 $SYSTEM_TREESIT_DIR 中查找已安装的语法..."

# 生成所有支持语言的包
for lang in "${LANGUAGES[@]}"; do
    generate_package "$lang"
done

echo ""
echo "🎉 包生成完成！"
echo "📁 包文件位置: $PACKAGES_DIR"
echo "📊 生成的包:"
ls -lah "$PACKAGES_DIR"/*.tar.gz 2>/dev/null || echo "   (没有生成任何包)"

echo ""
echo "💡 使用方法:"
echo "   1. 将生成的tar.gz文件提交到git仓库"
echo "   2. 重启Emacs，将自动从本地包安装Tree-sitter语法"
echo "   3. 或手动运行: M-x treesit-install-from-local"
