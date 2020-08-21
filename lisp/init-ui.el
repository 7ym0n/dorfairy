;;; init-ui.el ---                                   -*- lexical-binding: t; -*-

;; Copyright (C) 2020  7ym0n.q6e

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

;; Settings for UI theme
;; theme:
;;     doom-monokai-classic
;;     doom-snazzy
;;     doom-one-light
;;     doom-dark+
(use-package doom-themes
  :init (load-theme 'doom-one t))

;; Mode-line
(use-package doom-modeline
  :custom
  (doom-modeline-icon display-icon)
  (doom-modeline-minor-modes nil)
  (doom-modeline-unicode-fallback t)
  :hook (after-init . doom-modeline-mode)
  :init
  ;; Prevent flash of unstyled modeline at startup
  (unless after-init-time
    (setq doom-modeline--default-format mode-line-format)
    (setq-default mode-line-format nil))
  :bind (:map doom-modeline-mode-map))

;; need install all-the-icons fonts
;; web site https://github.com/domtronn/all-the-icons.el
(use-package all-the-icons)

;; Settings for delete multi line spaces
(use-package emacs
  :config
  (defalias 'yes-or-no-p 'y-or-n-p)
  ;; Display 'lambda' as 'λ' (just for fun)
  (global-prettify-symbols-mode 1)
  (set-default 'cursor-type 'bar)
  (setq default-frame-alist '((width . 180) (height . 40)))
  ;; (set-frame-parameter nil 'fullscreen 'maximized)
  ;; Set fonts global
  (set-face-attribute
   'default nil
   :font (font-spec :name "Ubuntu Mono"
                    :weight 'normal
                    :slant 'normal
                    :size 12.0))
  (dolist (charset '(kana han symbol cjk-misc bopomofo))
    (set-fontset-font
     (frame-parameter nil 'font)
     charset
     (font-spec :name "文泉驿等宽微米黑"
                :weight 'normal
                :slant 'normal
                :size 12.0)))

  (global-set-key (kbd "C-+") 'text-scale-increase)
  (global-set-key (kbd "C--") 'text-scale-decrease)
  (global-set-key (kbd "C-0") 'text-scale-adjust)
  :bind ((("M-/" . comment-line)
          ("M-?" . comment-or-uncomment-region)))
  :hook ((before-save . delete-trailing-whitespace)
         (after-init . delete-selection-mode))
  ;; Settings for the TAB behavior

  :init (setq-default tab-width 4
                      indent-tabs-mode nil
                      display-time-24hr-format t
                      display-time-day-and-date t)
  ;; Display time
  (display-time-mode 1))

;; Settings for line number
(use-package nlinum-relative
  :init
  (defvar custom-nlinum-relative--format-function
    (lambda (line width)
      (let* ((line-display (abs (- line nlinum-relative--current-line) ))
             (is-current-line? (eq line-display 0))
             (line-display (if is-current-line?
                               nlinum-relative--current-line
                             (+ nlinum-relative-offset line-display)))
             (str (if is-current-line?
                      (format nlinum-relative-current-symbol line-display) (format nlinum-format line-display)))
             )
        (when (< (length str) width)
          ;; Left pad to try and right-align the line-numbers.
          (setq str (concat (make-string (- width (length str)) ?\ ) str)))
        (if is-current-line?
            (put-text-property 0 width 'face 'nlinum-relative-current-face str)
          (put-text-property 0 width 'face 'linum str))
        str))
    "nlinum-relative to replace nlinum-format-function")
  (defun custom-nlinum-relative-toggle ()
    "Toggle between linum-relative and linum."
    (interactive)
    (if (eq nlinum-relative--format-function custom-nlinum-relative--format-function)
        (nlinum-relative-off)
      (nlinum-relative-on)))

  (setq nlinum-relative--format-function custom-nlinum-relative--format-function)
  (global-nlinum-relative-mode)
  :hook (nlinum-relative-toggle . custom-nlinum-relative-toggle)
  :config
  (setq nlinum-relative-current-symbol "%d->")
  (setq nlinum-relative-redisplay-delay 0)      ;; delay

  (setq nlinum-relative-offset 0))

;; Settings for electric-pair
(use-package electric
  :hook ((after-init . electric-indent-mode)
	     (prog-mode . electric-pair-mode)))

;; Settings for highlight parentheses
(use-package highlight-parentheses
  :hook (prog-mode . highlight-parentheses-mode))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))


(use-package centaur-tabs
  :demand
  :config
  (setq centaur-tabs-set-bar 'over
        centaur-tabs-set-icons t
        centaur-tabs-gray-out-icons 'buffer
        centaur-tabs-height 24
        centaur-tabs-set-modified-marker t
        centaur-tabs-modified-marker "•")
  (centaur-tabs-headline-match)
  (centaur-tabs-mode t))

(use-package dashboard
  :ensure t
  :init
  (dashboard-setup-startup-hook)
  :config
  (setq dashboard-set-heading-icons t)
  (setq dashboard-center-content t)
  (setq dashboard-set-file-icons t)
  (setq dashboard-items '((recents . 5)
                          (projects . 5)))
  )

(provide 'init-ui)
;;; init-ui.el ends here
