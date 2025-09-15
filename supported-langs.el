;;; supported-langs.el --- Tree-sitter 支持的语言列表配置  -*- lexical-binding: t; -*-

;; Copyright (C) 2024

;; Author: User
;; Keywords: tree-sitter, languages
;; Version: 1.0.0

;;; Commentary:

;; 此文件定义了支持的Tree-sitter语言列表和配置
;; 可以通过修改此文件来添加或删除支持的语言

;;; Code:

;; =============================================================================
;; 支持的语言列表配置
;; =============================================================================

(defvar treesit-local-supported-languages
  '(
    ;; 编程语言
    (c "c.tar.gz" "用于C语言支持")
    (cpp "cpp.tar.gz" "用于C++语言支持") 
    (python "python.tar.gz" "用于Python语言支持")
    (java "java.tar.gz" "用于Java语言支持")
    
    ;; Web相关
    (javascript "javascript.tar.gz" "用于JavaScript语言支持")
    (typescript "typescript.tar.gz" "用于TypeScript语言支持")
    (tsx "tsx.tar.gz" "用于TSX(TypeScript JSX)支持")
    (json "json.tar.gz" "用于JSON格式支持")
    (css "css.tar.gz" "用于CSS样式表支持")
    (html "html.tar.gz" "用于HTML标记语言支持")
    
    ;; 配置和脚本
    (bash "bash.tar.gz" "用于Bash脚本支持")
    (cmake "cmake.tar.gz" "用于CMake构建脚本支持")
    (dockerfile "dockerfile.tar.gz" "用于Dockerfile支持")
    
    ;; 其他语言（可选）
    (rust "rust.tar.gz" "用于Rust语言支持")
    (go "go.tar.gz" "用于Go语言支持")
    (elisp "elisp.tar.gz" "用于Emacs Lisp支持")
    )
  "支持的Tree-sitter语言列表
格式: (语言符号 包文件名 描述)")

;; =============================================================================
;; 配置函数
;; =============================================================================

(defun treesit-get-supported-languages ()
  "获取支持的语言列表"
  (mapcar #'car treesit-local-supported-languages))

(defun treesit-get-language-package (language)
  "获取指定语言的包文件名"
  (cadr (assoc language treesit-local-supported-languages)))

(defun treesit-get-language-description (language)
  "获取指定语言的描述"
  (caddr (assoc language treesit-local-supported-languages)))

(defun treesit-add-language-support (language package-file description)
  "添加新的语言支持
LANGUAGE: 语言符号
PACKAGE-FILE: tar.gz包文件名
DESCRIPTION: 语言描述"
  (interactive 
   (list (intern (read-string "语言名称 (如: python): "))
         (read-string "包文件名 (如: python.tar.gz): ")
         (read-string "描述: ")))
  
  (unless (assoc language treesit-local-supported-languages)
    (add-to-list 'treesit-local-supported-languages 
                 (list language package-file description))
    (message "✅ 已添加语言支持: %s" language))
  (message "⚠️  语言 %s 已存在" language))

(provide 'supported-langs)

;;; supported-langs.el ends here
