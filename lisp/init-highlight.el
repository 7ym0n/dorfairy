;;; init-highlight.el ---                                   -*- lexical-binding: t; -*-

;; Copyright © 2020-2024 b40yd

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
(require 'init-const)
(require 'init-custom)
(require 'init-funcs)


;; Colorize color names in buffers
(if emacs/28
    (use-package colorful-mode
      :diminish
      ;; :hook (after-init . global-colorful-mode)
      :init (setq colorful-use-prefix t
                  colorful-prefix-string "⯄")
      :config (dolist (mode '(html-mode php-mode help-mode helpful-mode))
                (add-to-list 'global-colorful-modes mode)))
  (use-package rainbow-mode
    :diminish
    :defines helpful-mode-map
    :hook ((html-mode css-mode php-mode helpful-mode) . rainbow-mode)
    :bind (:map special-mode-map
           ("w" . rainbow-mode))
    :init (with-eval-after-load 'helpful
            (bind-key "w" #'rainbow-mode helpful-mode-map))
    :config
    (with-no-warnings
      ;; HACK: Use overlay instead of text properties to override `hl-line' faces.
      ;; @see https://emacs.stackexchange.com/questions/36420
      (defun my-rainbow-colorize-match (color &optional match)
        (let* ((match (or match 0))
               (ov (make-overlay (match-beginning match) (match-end match))))
          (overlay-put ov 'ovrainbow t)
          (overlay-put ov 'face `((:foreground ,(if (> 0.5 (rainbow-x-color-luminance color))
                                                    "white" "black"))
                                  (:background ,color)))))
      (advice-add #'rainbow-colorize-match :override #'my-rainbow-colorize-match)

      (defun my-rainbow-clear-overlays ()
        "Clear all rainbow overlays."
        (remove-overlays (point-min) (point-max) 'ovrainbow t))
      (advice-add #'rainbow-turn-off :after #'my-rainbow-clear-overlays))))

;; Color picker https://github.com/ncruces/zenity/releases
;; Emacs not support xwidgets use zenity.

(unless (featurep 'xwidget-internal)
  (use-package webkit-color-picker
    :ensure t
    :bind (("C-c C-p" . webkit-color-picker-show)))
  (if (executable-find "zenity")
      (use-package zenity-color-picker
        :bind (("C-c C-p" . zenity-cp-color-at-point-dwim)))))

;; Highlight brackets according to their depth
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; Highlight TODO
(use-package hl-todo
  :defer t
  :hook (prog-mode . hl-todo-mode)
  :hook (yaml-mode . hl-todo-mode)
  :commands (hl-todo-rg-project hl-todo-rg)
  :init
  (map! :after hl-todo
        :map hl-todo-mode-map
        :leader
        :prefix "c"
        (:prefix-map ("k" . "keywords")
         :desc "Previous" "p" #'hl-todo-previous
         :desc "Next" "n" #'hl-todo-next
         :desc "Occur" "o" #'hl-todo-occur
         :desc "Insert" "i" #'hl-todo-insert
         :desc "Search" "s" #'hl-todo-rg
         :desc "Search project" "p" #'hl-todo-rg-project))
  :config
  (setq hl-todo-highlight-punctuation ":"
        hl-todo-keyword-faces
        '(;; For reminders to change or add something at a later date.
          ("TODO" warning bold)
          ;; For code (or code paths) that are broken, unimplemented, or slow,
          ;; and may become bigger problems later.
          ("FIXME" error bold)
          ;; For code that needs to be revisited later, either to upstream it,
          ;; improve it, or address non-critical issues.
          ("REVIEW" font-lock-keyword-face bold)
          ;; For code smells where questionable practices are used
          ;; intentionally, and/or is likely to break in a future update.
          ("HACK" font-lock-constant-face bold)
          ;; For sections of code that just gotta go, and will be gone soon.
          ;; Specifically, this means the code is deprecated, not necessarily
          ;; the feature it enables.
          ("DEPRECATED" font-lock-doc-face bold)
          ;; Extra keywords commonly found in the wild, whose meaning may vary
          ;; from project to project.
          ("NOTE" success bold)
          ("BUG" error bold)
          ("ISSUE" font-lock-constant-face bold)))


  (defadvice! +hl-todo-clamp-font-lock-fontify-region-a (fn &rest args)
    "Fix an `args-out-of-range' error in some modes."
    :around #'hl-todo-mode
    (letf! (defun font-lock-fontify-region (beg end &optional loudly)
             (funcall font-lock-fontify-region (max beg 1) end loudly))
      (apply fn args)))

  ;; Use a more primitive todo-keyword detection method in major modes that
  ;; don't use/have a valid syntax table entry for comments.
  (add-hook! '(pug-mode-hook haml-mode-hook)
    (defun +hl-todo--use-face-detection-h ()
      "Use a different, more primitive method of locating todo keywords."
      (set (make-local-variable 'hl-todo-keywords)
           '(((lambda (limit)
                (let (case-fold-search)
                  (and (re-search-forward hl-todo-regexp limit t)
                       (memq 'font-lock-comment-face (ensure-list (get-text-property (point) 'face))))))
              (1 (hl-todo-get-face) t t))))
      (when hl-todo-mode
        (hl-todo-mode -1)
        (hl-todo-mode +1))))
  (defun hl-todo-rg (regexp &optional files dir)
    "Use `rg' to find all TODO or similar keywords."
    (interactive
     (progn
       (unless (require 'rg nil t)
         (error "`rg' is not installed"))
       (let ((regexp (replace-regexp-in-string "\\\\[<>]*" "" (hl-todo--regexp))))
         (list regexp
               (rg-read-files)
               (read-directory-name "Base directory: " nil default-directory t)))))
    (rg regexp files dir))

  (defun hl-todo-rg-project ()
    "Use `rg' to find all TODO or similar keywords in current project."
    (interactive)
    (unless (require 'rg nil t)
      (error "`rg' is not installed"))
    (rg-project (replace-regexp-in-string "\\\\[<>]*" "" (hl-todo--regexp)) "everything"))
  )

;; Highlight uncommitted changes using VC
(use-package diff-hl
  :custom (diff-hl-draw-borders nil)
  :commands diff-hl-stage-current-hunk diff-hl-revert-hunk diff-hl-next-hunk diff-hl-previous-hunk
  :custom-face
  (diff-hl-change ((t (:inherit custom-changed :foreground unspecified :background unspecified))))
  (diff-hl-insert ((t (:inherit diff-added :background unspecified))))
  (diff-hl-delete ((t (:inherit diff-removed :background unspecified))))
  :bind (:map diff-hl-command-map
         ("SPC" . diff-hl-mark-hunk))
  :hook ((after-init   . global-diff-hl-mode)
         (after-init   . global-diff-hl-show-hunk-mouse-mode)
         (vc-dir-mode  . diff-hl-dir-mode)
         (find-file    . diff-hl-mode)
         (diff-hl-mode . diff-hl-flydiff-mode)
         (dired-mode   . diff-hl-dired-mode))
  :config
  ;; Highlight on-the-fly
  (diff-hl-flydiff-mode 1)

  ;; Set fringe style
  (setq-default fringes-outside-margins t)
  (with-no-warnings
    (defun my-diff-hl-fringe-bmp-function (_type _pos)
      "Fringe bitmap function for use as `diff-hl-fringe-bmp-function'."
      (define-fringe-bitmap 'my-diff-hl-bmp
        (vector (if IS-LINUX #b11111100 #b11100000))
        1 8
        '(center t)))
    (setq diff-hl-fringe-bmp-function #'my-diff-hl-fringe-bmp-function)

    (unless (display-graphic-p)
      ;; Fall back to the display margin since the fringe is unavailable in tty
      (diff-hl-margin-mode 1)
      ;; Avoid restoring `diff-hl-margin-mode'
      (with-eval-after-load 'desktop
        (add-to-list 'desktop-minor-mode-table
                     '(diff-hl-margin-mode nil))))

    ;; Integration with magit
    (with-eval-after-load 'magit
      (add-hook 'magit-pre-refresh-hook #'diff-hl-magit-pre-refresh)
      (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh))))

;; Pulse current line
(use-package pulse
  :ensure nil
  :hook (((dumb-jump-after-jump imenu-after-jump) . my-recenter-and-pulse)
         ((bookmark-after-jump magit-diff-visit-file next-error) . my-recenter-and-pulse-line))
  :init
  (with-no-warnings
    (defun my-pulse-momentary-line (&rest _)
      "Pulse the current line."
      (pulse-momentary-highlight-one-line (point)))

    (defun my-pulse-momentary (&rest _)
      "Pulse the region or the current line."
      (if (fboundp 'xref-pulse-momentarily)
          (xref-pulse-momentarily)
        (my-pulse-momentary-line)))

    (defun my-recenter-and-pulse(&rest _)
      "Recenter and pulse the region or the current line."
      (recenter)
      (my-pulse-momentary))

    (defun my-recenter-and-pulse-line (&rest _)
      "Recenter and pulse the current line."
      (recenter)
      (my-pulse-momentary-line))

    (dolist (cmd '(recenter-top-bottom
                   other-window switch-to-buffer
                   aw-select toggle-window-split
                   windmove-do-window-select
                   pager-page-down pager-page-up
                   treemacs-select-window))
      (advice-add cmd :after #'my-pulse-momentary-line))

    (dolist (cmd '(pop-to-mark-command
                   pop-global-mark
                   goto-last-change))
      (advice-add cmd :after #'my-recenter-and-pulse))))

;;; ui/indent-guides/config.el -*- lexical-binding: t; -*-

(defcustom +indent-guides-inhibit-functions ()
  "A list of predicate functions.

Each function will be run in the context of a buffer where `indent-bars' should
be enabled. If any function returns non-nil, the mode will not be activated."
  :type 'hook
  :group '+indent-guides)


;;
;;; Packages

(use-package indent-bars
  :hook ((prog-mode text-mode conf-mode) . +indent-guides-init-maybe-h)
  :init
  (defun +indent-guides-init-maybe-h ()
    "Enable `indent-bars-mode' depending on `+indent-guides-inhibit-functions'."
    (unless (run-hook-with-args-until-success '+indent-guides-inhibit-functions)
      (indent-bars-mode +1)))
  :custom
  (indent-bars-treesit-support t)
  (indent-bars-treesit-ignore-blank-lines-types '("module"))
  :config
  (setq indent-bars-prefer-character
        (or
         ;; Bitmaps are far slower on MacOS, inexplicably, but this needs more
         ;; testing to see if it's specific to ns or emacs-mac builds, or is
         ;; just a general MacOS issue.
         (featurep :system 'macos)
         ;; FIX: A bitmap init bug in PGTK builds of Emacs before v30 that could
         ;; cause crashes (see jdtsmith/indent-bars#3).
         (and (featurep 'pgtk)
              (< emacs-major-version 30)))

        ;; Show indent guides starting from the first column.
        indent-bars-starting-column 0
        ;; Make indent guides subtle; the default is too distractingly colorful.
        indent-bars-width-frac 0.15  ; make bitmaps thinner
        indent-bars-color-by-depth nil
        indent-bars-color '(font-lock-comment-face :face-bg nil :blend 0.425)
        ;; Don't highlight current level indentation; it's distracting and is
        ;; unnecessary overhead for little benefit.
        indent-bars-highlight-current-depth nil)

  (add-hook! '+indent-guides-inhibit-functions
             ;; Org's virtual indentation messes up indent-guides.
             (defun +indent-guides-in-org-indent-mode-p ()
               (bound-and-true-p org-indent-mode))
             ;; Fix #6438: indent-guides prevent inline images from displaying in ein
             ;; notebooks.
             (defun +indent-guides-in-ein-notebook-p ()
               (and (bound-and-true-p ein:notebook-mode)
                    (bound-and-true-p ein:output-area-inlined-images)))
             ;; Don't display indent guides in childframe popups (not helpful in
             ;; completion or eldoc popups).
             ;; REVIEW: Swap with `frame-parent' when 27 support is dropped
             (defun +indent-guides-in-childframe-p ()
               (frame-parameter nil 'parent-frame)))
  ;; HACK: Both indent-bars and tree-sitter-hl-mode use the jit-font-lock
  ;;   mechanism, and so they don't play well together. For those particular
  ;;   cases, we'll use `highlight-indent-guides', at least until the
  ;;   tree-sitter module adopts treesit.
  (defvar-local +indent-guides-p nil)
  (add-hook! 'tree-sitter-mode-hook :append
    (defun +indent-guides--toggle-on-tree-sitter-h ()
      (if tree-sitter-mode
          (when (bound-and-true-p indent-bars-mode)
            (with-memoization (get 'indent-bars-mode 'disabled-in-tree-sitter)
              (dotfairy-log "Disabled `indent-bars-mode' because it's not supported in `tree-sitter-mode'")
              t)
            (indent-bars-mode -1)
            (setq +indent-guides-p t))
        (when +indent-guides-p
          (indent-bars-mode +1)))))

  ;; HACK: `indent-bars-mode' interactions with some packages poorly. This
  ;;   section is dedicated to package interop fixes.
  (after! magit-blame
    (add-to-list 'magit-blame-disable-modes 'indent-bars-mode))

  ;; HACK: lsp-ui-peek uses overlays, and indent-bars doesn't know how to deal
  ;;   with all the whitespace it uses to format its popups, spamming it with
  ;;   indent guides. Making the two work together is a project for another
  ;;   day, so disable `indent-bars-mode' while its active instead. Doesn't
  ;;   affect character bars though.
  ;; REVIEW: Report this upstream to `indent-bars'?
  (defadvice! +indent-guides--remove-after-lsp-ui-peek-a (&rest _)
    :after #'lsp-ui-peek--peek-new
    (when (and indent-bars-mode
               (not indent-bars-prefer-character)
               (overlayp lsp-ui-peek--overlay))
      (save-excursion
        (let ((indent-bars--display-function #'ignore)
              (indent-bars--display-blank-lines-function #'ignore))
          (indent-bars--fontify (overlay-start lsp-ui-peek--overlay)
                                (1+ (overlay-end lsp-ui-peek--overlay))
                                nil)))))
  (defadvice! +indent-guides--restore-after-lsp-ui-peek-a (&rest _)
    :after #'lsp-ui-peek--peek-hide
    (unless indent-bars-prefer-character
      (indent-bars-setup))))

;; Highlight the current line
(use-package hl-line
  :ensure nil
  :hook ((after-init . global-hl-line-mode)
         ((dashboard-mode eshell-mode shell-mode term-mode vterm-mode) .
          (lambda () (setq-local global-hl-line-mode nil)))))

;; Highlight matching parens
(use-package paren
  :ensure nil
  :hook (after-init . show-paren-mode)
  :init (setq show-paren-when-point-inside-paren t
              show-paren-when-point-in-periphery t)
  :config
  (if (>= emacs-major-version 29)
      (setq show-paren-context-when-offscreen
            (if (childframe-workable-p) 'child-frame 'overlay))
    (with-no-warnings
      ;; Display matching line for off-screen paren.
      (defun display-line-overlay (pos str &optional face)
        "Display line at POS as STR with FACE.
FACE defaults to inheriting from default and highlight."
        (let ((ol (save-excursion
                    (goto-char pos)
                    (make-overlay (line-beginning-position)
                                  (line-end-position)))))
          (overlay-put ol 'display str)
          (overlay-put ol 'face
                       (or face '(:inherit highlight)))
          ol))

      (defvar-local show-paren--off-screen-overlay nil)
      (defun show-paren-off-screen (&rest _args)
        "Display matching line for off-screen paren."
        (when (overlayp show-paren--off-screen-overlay)
          (delete-overlay show-paren--off-screen-overlay))
        ;; Check if it's appropriate to show match info,
        (when (and (overlay-buffer show-paren--overlay)
                   (not (or cursor-in-echo-area
                            executing-kbd-macro
                            noninteractive
                            (minibufferp)
                            this-command))
                   (and (not (bobp))
                        (memq (char-syntax (char-before)) '(?\) ?\$)))
                   (= 1 (logand 1 (- (point)
                                     (save-excursion
                                       (forward-char -1)
                                       (skip-syntax-backward "/\\")
                                       (point))))))
          ;; Rebind `minibuffer-message' called by `blink-matching-open'
          ;; to handle the overlay display.
          (cl-letf (((symbol-function #'minibuffer-message)
                     (lambda (msg &rest args)
                       (let ((msg (apply #'format-message msg args)))
                         (setq show-paren--off-screen-overlay
                               (display-line-overlay
                                (window-start) msg ))))))
            (blink-matching-open))))
      (advice-add #'show-paren-function :after #'show-paren-off-screen))))

;; Pulse modified region
(use-package goggles
  :diminish
  :hook ((prog-mode text-mode) . goggles-mode))

(provide 'init-highlight)
;;; init-highlight.el ends here
