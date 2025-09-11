# Tree-sitter Grammar Packages

此目录用于存放预编译的Tree-sitter语法包。

## 目录结构

```
treesit-grammars/
├── README.md           # 说明文件
├── supported-langs.el  # 支持的语言列表配置
└── packages/           # 语法包存放目录
    ├── c.tar.gz
    ├── cpp.tar.gz
    ├── python.tar.gz
    ├── javascript.tar.gz
    ├── typescript.tar.gz
    ├── java.tar.gz
    └── json.tar.gz
```

## 添加新语言支持

1. 将对应语言的tar.gz包放入`packages/`目录
2. 在`supported-langs.el`中添加语言配置
3. 重启Emacs或运行`M-x treesit-install-from-local`

## 语法包来源

语法包可以从以下方式获取：
- 从Tree-sitter官方仓库编译
- 使用`treesit-install-language-grammar`下载后打包
- 从其他系统复制已编译的.so文件
