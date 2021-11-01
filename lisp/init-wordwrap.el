;;; init-wordwrap.el ---                                   -*- lexical-binding: t; -*-

;; Copyright © 2021, 7ym0n, all rights reserved.

;; Author: 7ym0n <bb.qnyd@gmail.com>
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
(require 'cl-lib)
(require 'dash)

(use-package adaptive-wrap
  :commands global-word-wrap-mode
  :hook (after-init . (lambda ()
                        (global-word-wrap-mode)))
  :init
  (with-eval-after-load 'adaptive-wrap
    (defvar +word-wrap-extra-indent 'double
      "The amount of extra indentation for wrapped code lines.
When 'double, indent by twice the major-mode indentation.
When 'single, indent by the major-mode indentation.
When a positive integer, indent by this fixed amount.
When a negative integer, dedent by this fixed amount.
Otherwise no extra indentation will be used.")

    (defvar +word-wrap-disabled-modes
      '(fundamental-mode so-long-m      ode)
      "Major-modes where `global-word-wrap-mode' should not enable
                  `+word-wrap-mode'.")

    (defvar +word-wrap-visual-modes
      '(org-mode)
      "Major-modes where `+word-wrap-mode' should not use
`adaptive-wrap-prefix-mode'.")

    (defvar +word-wrap-text-modes
      '(text-mode markdown-mode markdown-view-mode gfm-mode gfm-view-mode rst-mode
                  latex-mode LaTeX-mode)
      "Major-modes where `+word-wrap-mode' should not provide extra indentation.")

    (when (memq 'visual-line-mode text-mode-hook)
      (remove-hook 'text-mode-hook #'visual-line-mode)
      (add-hook 'text-mode-hook #'+word-wrap-mode))

    (defvar +word-wrap--major-mode-is-visual nil)
    (defvar +word-wrap--major-mode-is-text nil)
    (defvar +word-wrap--enable-adaptive-wrap-mode nil)
    (defvar +word-wrap--enable-visual-line-mode nil)
    (defvar +word-wrap--major-mode-indent-var nil)

    (defvar adaptive-wrap-extra-indent)
    (defun +word-wrap--adjust-extra-indent-a (orig-fn beg end)
      "Contextually adjust extra word-wrap indentation."
      (let ((adaptive-wrap-extra-indent (+word-wrap--calc-extra-indent beg)))
        (funcall orig-fn beg end)))

    (cl-defstruct text-state
      ;; The last point checked by text--syntax-ppss and its result, used for
      ;; memoization
      last-syntax-ppss-point ;; a list (point point-min point-max)
      last-syntax-ppss-result
      )

    (defvar-local text-state (make-text-state)
      "State for the current buffer.")
    (defun text--reset-memoization (&rest ignored)
      "Reset memoization as a safety precaution.
IGNORED is a dummy argument used to eat up arguments passed from
the hook where this is executed."
      (setf (text-state-last-syntax-ppss-point text-state) nil
            (text-state-last-syntax-ppss-result text-state) nil))
    (defun text--syntax-ppss (&optional p)
      "Memoize the last result of `syntax-ppss'.
P is the point at which we run `syntax-ppss'"
      (let ((p (or p (point)))
            (mem-p (text-state-last-syntax-ppss-point text-state)))
        (if (and (eq p (nth 0 mem-p))
                 (eq (point-min) (nth 1 mem-p))
                 (eq (point-max) (nth 2 mem-p)))
            (text-state-last-syntax-ppss-result text-state)
          ;; Add hook to reset memoization if necessary
          (unless (text-state-last-syntax-ppss-point text-state)
            (add-hook 'before-change-functions 'text--reset-memoization t t))
          (setf (text-state-last-syntax-ppss-point text-state)
                (list p (point-min) (point-max))
                (text-state-last-syntax-ppss-result text-state) (syntax-ppss p)))))

    (defun text-point-in-string (&optional p)
      "Return non-nil if point is inside string or documentation string.
This function actually returns the 3rd element of `syntax-ppss'
which can be a number if the string is delimited by that
character or t if the string is delimited by general string
fences.
If optional argument P is present test this instead of point."
      (ignore-errors
        (save-excursion
          (nth 3 (text--syntax-ppss p)))))

    (defun text-point-in-comment (&optional p)
      "Return non-nil if point is inside comment.
If optional argument P is present test this instead off point."
      (setq p (or p (point)))
      (ignore-errors
        (save-excursion
          ;; We cannot be in a comment if we are inside a string
          (unless (nth 3 (text--syntax-ppss p))
            (or (nth 4 (text--syntax-ppss p))
                ;; this also test opening and closing comment delimiters... we
                ;; need to chack that it is not newline, which is in "comment
                ;; ender" class in elisp-mode, but we just want it to be
                ;; treated as whitespace
                (and (< p (point-max))
                     (memq (char-syntax (char-after p)) '(?< ?>))
                     (not (eq (char-after p) ?\n)))
                ;; we also need to test the special syntax flag for comment
                ;; starters and enders, because `syntax-ppss' does not yet
                ;; know if we are inside a comment or not (e.g. / can be a
                ;; division or comment starter...).
                (-when-let (s (car (syntax-after p)))
                  (or (and (/= 0 (logand (lsh 1 16) s))
                           (nth 4 (syntax-ppss (+ p 2))))
                      (and (/= 0 (logand (lsh 1 17) s))
                           (nth 4 (syntax-ppss (+ p 1))))
                      (and (/= 0 (logand (lsh 1 18) s))
                           (nth 4 (syntax-ppss (- p 1))))
                      (and (/= 0 (logand (lsh 1 19) s))
                           (nth 4 (syntax-ppss (- p 2)))))))))))

    (defun text-point-in-string-or-comment (&optional p)
      "Return non-nil if point is inside string, documentation string or a comment.
If optional argument P is present, test this instead of point."
      (or (text-point-in-string p)
          (text-point-in-comment p)))

    (defun +word-wrap--calc-extra-indent (p)
      "Calculate extra word-wrap indentation at point."
      (if (not (or +word-wrap--major-mode-is-text
                   (text-point-in-string-or-comment p)))
          (pcase +word-wrap-extra-indent
            ('double
             (* 2 (symbol-value +word-wrap--major-mode-indent-var)))
            ('single
             (symbol-value +word-wrap--major-mode-indent-var))
            ((and (pred integerp) fixed)
             fixed)
            (_ 0))
        0))

    (defvar word-wrap-indent-hook-mapping-list
      ;;   Mode            Syntax              Variable
      '((c-mode          c/c++/java    c-basic-offset)       ; C
        (c++-mode        c/c++/java    c-basic-offset)       ; C++
        (d-mode          c/c++/java    c-basic-offset)       ; D
        (java-mode       c/c++/java    c-basic-offset)       ; Java
        (jde-mode        c/c++/java    c-basic-offset)       ; Java (JDE)
        (js-mode         javascript    js-indent-level)      ; JavaScript
        (js2-mode        javascript    js2-basic-offset)     ; JavaScript-IDE
        (js3-mode        javascript    js3-indent-level)     ; JavaScript-IDE
        (json-mode       javascript    js-indent-level)      ; JSON
        (lua-mode        lua           lua-indent-le                vel)     ; Lua
        (objc-mode       c/c++/java    c-basic-offset)       ; Objective C
        (php-mode        c/c++/java    c-basic-offset)       ; PHP
        (perl-mode       perl          perl-indent-level)    ; Perl
        (cperl-mode      perl          cperl-indent-level)   ; Perl
        (raku-mode       perl          raku-indent-offset)   ; Perl6/Raku
        (erlang-mode     erlang        erlang-indent-level)  ; Erlang
        (ada-mode        ada           ada-indent)           ; Ada
        (sgml-mode       sgml          sgml-basic-offset)    ; SGML
        (nxml-mode       sgml          nxml-child-indent)    ; XML
        (pascal-mode     pascal        pascal-indent-level)  ; Pascal
        (typescript-mode javascript    typescript-indent-level) ; Typescript
        (protobuf-mode   c/c++/java    c-basic-offset)       ; Protobuf
        (plantuml-mode   default       plantuml-indent-level) ; PlantUML
        (pug-mode        default       pug-tab-width)         ; Pug
        (cmake-mode      cmake         cmake-tab-width)       ; CMake

        ;; Modes that use SMIE if available
        (sh-mode         default       sh-basic-offset)      ; Shell Script
        (ruby-mode       ruby          ruby-indent-level)    ; Ruby
        (enh-ruby-mode   ruby          enh-ruby-indent-level); Ruby
        (crystal-mode    ruby          crystal-indent-level) ; Crystal (Ruby)
        (css-mode        css           css-indent-offset)    ; CSS
        (rust-mode       c/c++/java    rust-indent-offset)   ; Rust
        (rustic-mode     c/c++/java    rustic-indent-offset) ; Rust
        (scala-mode      c/c++/java    scala-indent:step)    ; Scala

        (default         default       standard-indent))     ; default fallback
      "A mapping from hook variables to language types.")

    (defun word-wrap-indent-search-hook-mapping (mode)
      "Search hook-mapping for MODE or its derived-mode-parent."
      (if mode
          (or (assoc mode word-wrap-indent-hook-mapping-list)
              (word-wrap-indent-search-hook-mapping (get mode 'derived-mode-parent))
              (assoc 'default word-wrap-indent-hook-mapping-list))))

    (define-minor-mode +word-wrap-mode
      "Wrap long lines in the buffer with language-aware indentation.
This mode configures `adaptive-wrap' and `visual-line-mode' to wrap long lines
without modifying the buffer content. This is useful when dealing with legacy
code which contains gratuitously long lines, or running emacs on your
wrist-phone.
Wrapped lines will be indented to match the preceding line. In code buffers,
lines which are not inside a string or comment will have additional indentation
according to the configuration of `+word-wrap-extra-indent'."
      :init-value nil
      (if +word-wrap-mode
          (progn
            (setq-local +word-wrap--major-mode-is-visual
                        (memq major-mode +word-wrap-visual-modes))
            (setq-local +word-wrap--major-mode-is-text
                        (memq major-mode +word-wrap-text-modes))

            (setq-local +word-wrap--enable-adaptive-wrap-mode
                        (and (not (bound-and-true-p adaptive-wrap-prefix-mode))
                             (not +word-wrap--major-mode-is-visual)))

            (setq-local +word-wrap--enable-visual-line-mode
                        (not (bound-and-true-p visual-line-mode)))

            (unless +word-wrap--major-mode-is-visual
              (setq-local +word-wrap--major-mode-indent-var
                          (caddr (word-wrap-indent-search-hook-mapping major-mode)))

              (advice-add #'adaptive-wrap-fill-context-prefix :around #'+word-wrap--adjust-extra-indent-a))

            (when +word-wrap--enable-adaptive-wrap-mode
              (adaptive-wrap-prefix-mode +1))
            (when +word-wrap--enable-visual-line-mode
              (visual-line-mode +1)))

        ;; disable +word-wrap-mode
        (unless +word-wrap--major-mode-is-visual
          (advice-remove #'adaptive-wrap-fill-context-prefix #'+word-wrap--adjust-extra-indent-a))

        (when +word-wrap--enable-adaptive-wrap-mode
          (adaptive-wrap-prefix-mode -1))
        (when +word-wrap--enable-visual-line-mode
          (visual-line-mode -1))))

    (defun +word-wrap--enable-global-mode ()
      "Enable `+word-wrap-mode' for `+word-wrap-global-mode'.
Wrapping will be automatically enabled in all modes except special modes, or
modes explicitly listed in `+word-wrap-disabled-modes'."
      (unless (or (eq (get major-mode 'mode-class) 'special)
                  (memq major-mode +word-wrap-disabled-modes))
        (+word-wrap-mode +1)))
    (define-globalized-minor-mode global-word-wrap-mode
      +word-wrap-mode
      +word-wrap--enable-global-mode)))

(provide 'init-wordwrap)
;;; init-wordwrap.el ends here
