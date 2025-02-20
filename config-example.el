;;; config.el ---                                    -*- lexical-binding: t; -*-

;; Copyright (C) 2020

;; Author: 7ym0n.q6e <bb.qnyd@gmail.com>
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
(require 'init-const)
(require 'init-custom)

(setq warning-minimum-level :error)  ; set warning minimum level default `:error',or `:debug' or `:warning' or `:emergency'

(setq dotfairy-full-name "user name")           ; User full name
(setq dotfairy-mail-address "user@email.com")   ; Email address
;; (setq dotfairy-proxy "127.0.0.1:1080")          ; Network proxy
(setq dotfairy-keybind-mode 'evil)       ; Enable `vim-like' or `emacs'
(setq dotfairy-quelpa-upgrade nil) ; Enable `quelpa-upgrade-p' t or nil
;; (setq dotfairy-completion-style 'childframe) ; Completion display style default `childframe', or set `minibuffer'.
;; (setq dotfairy-server nil)                      ; Enable `server-mode' or not: t or nil
(setq dotfairy-package-archives 'netease)   ; Package repo: melpa, emacs-cn, netease, bfsu, sjtu, ustc or tuna
;; Color theme:
;; dotfairy-theme-list
;; '((default . doom-one)
;;   (doom-one . doom-one)
;;   (doom-monokai-pro     . doom-monokai-pro)
;;   (doom-dark+    . doom-dark+)
;;   (doom-one-light   . doom-one-light)
;;   (doom-solarized-light    . doom-solarized-light)
;;   (doom-city-lights    . doom-city-lights)
;;   (doom-tomorrow-day    . doom-tomorrow-day)
;;   (doom-tomorrow-night   . doom-tomorrow-night))
(setq dotfairy-theme 'default)
(setq dotfairy-lsp 'lsp-mode)   ;; Use lsp-mode, eglot or nil code complete
;; (setq dotfairy-dashboard nil)                   ; Use dashboard at startup or not: t or nil
(setq dotfairy-lsp-format-on-save-ignore-modes '(c-mode c++-mode python-mode go-mode)) ; Ignore format on save for some languages
(setq dotfairy-lsp-format-on-save t) ; auto format on save
;; (setq dotfairy-company-prescient nil) ; Enable `company-prescient' or not. it's on Windows 10 very slow.
;; confirm exit emacs
(setq confirm-kill-emacs 'y-or-n-p)
(setq ssh-manager-sessions '()) ;Add SSH connect sessions
;;(setq dotfairy-org-repository "") ; Set Org git repository url address.

;; Fonts
(defun dotfairy-setup-fonts ()
  "Setup fonts."
  (when (display-graphic-p)
    ;; Set default font
    (cl-loop for font in '("Cascadia Code" "Fira Code" "Jetbrains Mono"
                           "SF Mono" "Hack" "Source Code Pro" "Menlo"
                           "Monaco" "DejaVu Sans Mono" "Consolas")
             when (font-installed-p font)
             return (set-face-attribute 'default nil
                                        :family font
                                        :height (cond (IS-MAC 180)
                                                      (IS-WINDOWS 110)
                                                      (t 130))))

    ;; Specify font for all unicode characters
    (cl-loop for font in '("Apple Symbols" "PowerlineSymbols" "Apple Color Emoji" "Segoe UI Symbol" "Symbola" "Symbol")
             when (font-installed-p font)
             return (if (< emacs-major-version 27)
                        (set-fontset-font "fontset-default" 'unicode font nil 'prepend)
                      (set-fontset-font t 'symbol (font-spec :family font) nil 'prepend)))

    ;; Emoji
    (cl-loop for font in '("Noto Color Emoji" "Apple Color Emoji" "Segoe UI Emoji")
             when (font-installed-p font)
             return (set-fontset-font t
                                      (if (< emacs-major-version 28)'symbol 'emoji)
                                      (font-spec :family font) nil 'prepend))

    ;; Specify font for Chinese characters
    (cl-loop for font in '("LXGW Neo Xihei" "WenQuanYi Micro Hei Mono" "LXGW WenKai Screen"
                           "LXGW WenKai Mono" "PingFang SC" "Microsoft Yahei UI" "Simhei")
             when (font-installed-p font)
             return (progn
                      (setq face-font-rescale-alist `((,font . 1.3)))
                      (set-fontset-font t 'han (font-spec :family font))))))

(dotfairy-setup-fonts)
(add-hook 'window-setup-hook #'dotfairy-setup-fonts)
(add-hook 'server-after-make-frame-hook #'dotfairy-setup-fonts)

;; default workspace
(setq default-directory "~/")


;; .authinfo
;; machine api.gitlab.com/api/v4 login <your_git_user>^forge password <your_git_auth_token>
;; machine api.github.com login forge^forge password <your_git_auth_token>
;; this setting private repository code review.
;; machine <your_private_repo_domain_or_ip>/api login <your_git_user>^forge password <your_git_auth_token>
;;
(with-eval-after-load 'forge
  ;; if use private repository, your must be add to there.
  ;; (push '("api.gitlab.com" "api.gitlab.com/api/v4" "api.gitlab.com" forge-gitlab-repository) forge-alist)
  ;; (push '("api.github.com" "api.github.com/api/v4" "api.github.com" forge-github-repository) forge-alist)
  )


;; setting proxy
;; (dotfairy/toggle-http-proxy)
;; (dotfairy/toggle-socks-proxy)

;; (byte-recompile-directory package-user-dir 0 0) ;
;;; config.el ends here
