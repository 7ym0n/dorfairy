;;; init-markdown.el ---                             -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2024 b40yd

;; Author: b40yd <bb.qnyd@gmail.com>
;; Keywords:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:
(require 'init-funcs)

(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode))
  :init
  (setq markdown-enable-wiki-links t
        markdown-italic-underscore t
        markdown-asymmetric-header t
        markdown-make-gfm-checkboxes-buttons t
        markdown-gfm-uppercase-checkbox t
        markdown-fontify-whole-heading-line t
        markdown-fontify-code-blocks-natively t
        markdown-split-window-direction 'right
        markdown-open-command
        (cond (IS-MAC "open")
              (IS-LINUX "xdg-open"))
        markdown-content-type "application/xhtml+xml"
        markdown-css-paths
        '("https://cdn.jsdelivr.net/npm/github-markdown-css/github-markdown.min.css"
          "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release/build/styles/github.min.css")
        markdown-xhtml-header-content
        (concat "<meta name='viewport' content='width=device-width, initial-scale=1, shrink-to-fit=no'>"
                "<style> body { box-sizing: border-box; max-width: 740px; width: 100%; margin: 40px auto; padding: 0 10px; } </style>"
                "<script id='MathJax-script' src='https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js'></script>"
                "<link rel='stylesheet' href='https://cdn.jsdelivr.net/gh/highlightjs/cdn-release/build/styles/default.min.css'>"
                "<script src='https://cdn.jsdelivr.net/gh/highlightjs/cdn-release/build/highlight.min.js'></script>"
                "<script>document.addEventListener('DOMContentLoaded', () => { document.body.classList.add('markdown-body'); document.querySelectorAll('pre[lang] > code').forEach((code) => { code.classList.add(code.parentElement.lang); }); document.querySelectorAll('pre > code').forEach((code) => { if (code.className != 'mermaid') {hljs.highlightBlock(code);} }); });</script>"
                "<script src='https://unpkg.com/mermaid@8.4.8/dist/mermaid.min.js'></script>"
                "<script>mermaid.initialize({theme: 'default',startOnLoad: true});</script>"
                )
        markdown-gfm-additional-languages "Mermaid")

  ;; `multimarkdown' is necessary for `highlight.js' and `mermaid.js'
  (when (executable-find "multimarkdown")
    (setq markdown-command "multimarkdown"))

  ;; Use `which-key' instead
  (with-no-warnings
    (advice-add #'markdown--command-map-prompt :override #'ignore)
    (advice-add #'markdown--style-map-prompt   :override #'ignore))
  :config
  ;; Support `mermaid'
  (add-to-list 'markdown-code-lang-modes '("mermaid" . mermaid-mode))

  (with-no-warnings
    ;; Preview with built-in webkit
    (defun my-markdown-export-and-preview (fn)
      "Preview with `xwidget' if applicable, otherwise with the default browser."
      (if (and (featurep 'xwidget-internal) (display-graphic-p))
          (dotfairy-webkit-browse-url (concat "file://" (markdown-export)) t)
        (funcall fn)))
    (advice-add #'markdown-export-and-preview :around #'my-markdown-export-and-preview)))

;; Table of contents
(use-package markdown-toc
  :diminish
  :bind (:map markdown-mode-command-map
         ("r" . markdown-toc-generate-or-refresh-toc))
  :hook (markdown-mode . markdown-toc-mode)
  :init (setq markdown-toc-indentation-space 2
              markdown-toc-header-toc-title "\n## Table of Contents"
              markdown-toc-user-toc-structure-manipulation-fn 'cdr)
  :config
  (with-no-warnings
    (define-advice markdown-toc-generate-toc (:around (fn &rest args) lsp)
      "Generate or refresh toc after disabling lsp."
      (cond
       ((bound-and-true-p lsp-managed-mode)
        (lsp-managed-mode -1)
        (apply fn args)
        (lsp-managed-mode 1))
       ((bound-and-true-p eglot--manage-mode)
        (eglot--manage-mode -1)
        (apply fn args)
        (eglot--manage-mode 1))
       (t
        (apply fn args))))))

;; Preview markdown files
;; @see: https://github.com/seagle0128/grip-mode?tab=readme-ov-file#prerequisite
(use-package grip-mode
  :defines markdown-mode-command-map org-mode-map
  :functions auth-source-user-and-password
  :autoload grip-mode
  :init
  (with-eval-after-load 'markdown-mode
    (bind-key "g" #'grip-mode markdown-mode-command-map))
  (with-eval-after-load 'org
    (bind-key "C-c C-g" #'grip-mode org-mode-map))
  (setq grip-update-after-change nil)
  ;; mdopen doesn't need credentials, and only support external browsers
  (if (executable-find "mdopen")
      (setq grip-use-mdopen t)
    (when-let* ((credential (and (require 'auth-source nil t)
                                 (auth-source-user-and-password "api.github.com"))))
      (setq grip-github-user (car credential)
            grip-github-password (cadr credential)))))

(map! :map markdown-mode-map
      :localleader
      "'" #'markdown-edit-code-block
      "o" #'markdown-open
      "p" #'markdown-preview
      "e" #'markdown-export
      "p" #'grip-mode
      (:prefix ("i" . "insert")
       :desc "Table Of Content"  "T" #'markdown-toc-generate-toc
       :desc "Image"             "i" #'markdown-insert-image
       :desc "Link"              "l" #'markdown-insert-link
       :desc "<hr>"              "-" #'markdown-insert-hr
       :desc "Heading 1"         "1" #'markdown-insert-header-atx-1
       :desc "Heading 2"         "2" #'markdown-insert-header-atx-2
       :desc "Heading 3"         "3" #'markdown-insert-header-atx-3
       :desc "Heading 4"         "4" #'markdown-insert-header-atx-4
       :desc "Heading 5"         "5" #'markdown-insert-header-atx-5
       :desc "Heading 6"         "6" #'markdown-insert-header-atx-6
       :desc "Code block"        "C" #'markdown-insert-gfm-code-block
       :desc "Pre region"        "P" #'markdown-pre-region
       :desc "Blockquote region" "Q" #'markdown-blockquote-region
       :desc "Checkbox"          "[" #'markdown-insert-gfm-checkbox
       :desc "Bold"              "b" #'markdown-insert-bold
       :desc "Inline code"       "c" #'markdown-insert-code
       :desc "Italic"            "e" #'markdown-insert-italic
       :desc "Footnote"          "f" #'markdown-insert-footnote
       :desc "Header dwim"       "h" #'markdown-insert-header-dwim
       :desc "Italic"            "i" #'markdown-insert-italic
       :desc "Kbd"               "k" #'markdown-insert-kbd
       :desc "Pre"               "p" #'markdown-insert-pre
       :desc "New blockquote"    "q" #'markdown-insert-blockquote
       :desc "Strike through"    "s" #'markdown-insert-strike-through
       :desc "Table"             "t" #'markdown-insert-table
       :desc "Wiki link"         "w" #'markdown-insert-wiki-link)
      (:prefix ("t" . "toggle")
       :desc "Inline LaTeX"      "e" #'markdown-toggle-math
       :desc "Code highlights"   "f" #'markdown-toggle-fontify-code-blocks-natively
       :desc "Inline images"     "i" #'markdown-toggle-inline-images
       :desc "URL hiding"        "l" #'markdown-toggle-url-hiding
       :desc "Markup hiding"     "m" #'markdown-toggle-markup-hiding
       :desc "Wiki links"        "w" #'markdown-toggle-wiki-links
       :desc "GFM checkbox"      "x" #'markdown-toggle-gfm-checkbox))

(provide 'init-markdown)
;;; init-markdown.el ends here
