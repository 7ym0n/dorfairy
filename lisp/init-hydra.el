;;; init-hydra.el
;;;
;;; (c) 7ym0n, https://gitlab.com/7ym0n/dotfairy
;;;
(use-package hydra
  :hook (emacs-lisp-mode . hydra-add-imenu)
  :init
  (when (childframe-completion-workable-p)
    (setq hydra-hint-display-type 'posframe)

    (with-eval-after-load 'posframe
      (defun hydra-set-posframe-show-params ()
        "Set hydra-posframe style."
        (setq hydra-posframe-show-params
              `(:left-fringe 8
                :right-fringe 8
                :internal-border-width 2
                :internal-border-color ,(face-background 'posframe-border nil t)
                :background-color ,(face-background 'tooltip nil t)
                :foreground-color ,(face-foreground 'tooltip nil t)
                :lines-truncate t
                :poshandler posframe-poshandler-frame-center-near-bottom)))
      (hydra-set-posframe-show-params)
      (add-hook 'after-load-theme-hook #'hydra-set-posframe-show-params t))))

(use-package pretty-hydra
  :hook (emacs-lisp-mode . (lambda ()
                             (add-to-list
                              'imenu-generic-expression
                              '("Hydras"
                                "^.*(\\(pretty-hydra-define\\) \\([a-zA-Z-]+\\)"
                                2))))
  :bind ("C-c <f2>" . toggles-hydra/body)
  :init
  (with-no-warnings
    (cl-defun pretty-hydra-title (title &optional icon-type icon-name
                                        &key face height v-adjust)
      "Add an icon in the hydra title."
      (let ((face (or face 'mode-line-emphasis))
            (height (or height 1.0))
            (v-adjust (or v-adjust 0.0)))
        (concat
         (when (and (icons-displayable-p) icon-type icon-name)
           (let ((f (intern (format "nerd-icons-%s" icon-type))))
             (when (fboundp f)
               (concat
                (apply f (list icon-name :face face :height height :v-adjust v-adjust))
                " "))))
         (propertize title 'face face))))

    ;; Global toggles
    (pretty-hydra-define toggles-hydra (:title (pretty-hydra-title "Toggles" 'faicon "nf-fa-toggle_on")
                                        :color amaranth :quit-key "q")
      ("Basic"
       (("n" (cond ((fboundp 'display-line-numbers-mode)
                    (display-line-numbers-mode (if display-line-numbers-mode -1 1)))
                   ((fboundp 'gblobal-linum-mode)
                    (global-linum-mode (if global-linum-mode -1 1))))
         "line number"
         :toggle (or (bound-and-true-p display-line-numbers-mode)
                     (bound-and-true-p global-linum-mode)))
        ("a" global-aggressive-indent-mode "aggressive indent" :toggle t)
        ("h" global-hungry-delete-mode "hungry delete" :toggle t)
        ("e" electric-pair-mode "electric pair" :toggle t)
        ("c" flyspell-mode "spell check" :toggle t)
        ("S" prettify-symbols-mode "pretty symbol" :toggle t)
        ("L" global-page-break-lines-mode "page break lines" :toggle t)
        ("M" doom-modeline-mode "modern mode-line" :toggle t))
       "Highlight"
       (("l" global-hl-line-mode "line" :toggle t)
        ("P" show-paren-mode "paren" :toggle t)
        ("s" symbol-overlay-mode "symbol" :toggle t)
        ("r" rainbow-mode "rainbow" :toggle t)
        ("w" (setq-default show-trailing-whitespace (not show-trailing-whitespace))
         "whitespace" :toggle show-trailing-whitespace)
        ("d" rainbow-delimiters-mode "delimiter" :toggle t)
        ("i" indent-bars-mode "indent" :toggle t)
        ("T" global-hl-todo-mode "todo" :toggle t))
       "Coding"
       (("f" flymake-mode "flymake" :toggle t)
        ("O" hs-minor-mode "hideshow" :toggle t)
        ("u" subword-mode "subword" :toggle t)
        ("W" which-function-mode "which function" :toggle t)
        ("E" toggle-debug-on-error "debug on error" :toggle (default-value 'debug-on-error))
        ("Q" toggle-debug-on-quit "debug on quit" :toggle (default-value 'debug-on-quit)))
       ))))

(provide 'init-hydra)
