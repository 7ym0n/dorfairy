;;; init-dired.el ---                                -*- lexical-binding: t; -*-

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
(require 'init-const)
(require 'init-custom)
(require 'init-funcs)

(use-package dired
  :ensure nil
  :config
  ;; Guess a default target directory
  (setq dired-dwim-target t)

  ;; Always delete and copy recursively
  (setq dired-auto-revert-buffer t  ; don't prompt to revert; just do it
        dired-dwim-target t  ; suggest a target for moving/copying intelligently
        dired-hide-details-hide-symlink-targets nil
        ;; Always copy/delete recursively
        dired-recursive-copies  'always
        dired-recursive-deletes 'always
        ;; Ask whether destination dirs should get created when copying/removing files.
        dired-create-destination-dirs 'ask
        ;; Where to store image caches
        image-dired-dir (concat dotfairy-cache-dir "image-dired/")
        image-dired-db-file (concat image-dired-dir "db.el")
        image-dired-gallery-dir (concat image-dired-dir "gallery/")
        image-dired-temp-image-file (concat image-dired-dir "temp-image")
        image-dired-temp-rotate-image-file (concat image-dired-dir "temp-rotate-image")
        ;; Screens are larger nowadays, we can afford slightly larger thumbnails
        image-dired-thumb-size 150)

  ;; Show directory first
  (setq dired-listing-switches "-alh --group-directories-first")

  (when IS-MAC
    (if (executable-find "gls")
        (progn
          ;; Use GNU ls as `gls' from `coreutils' if available.
          (setq insert-directory-program "gls")
          ;; Using `insert-directory-program'
          (setq ls-lisp-use-insert-directory-program t))
      (progn
        ;; Suppress the warning: `ls does not support --dired'.
        (setq dired-use-ls-dired nil)
        (setq dired-listing-switches "-alh"))))

  ;; Quick sort dired buffers via hydra
  (use-package dired-quick-sort
    :bind (:map dired-mode-map
           ("S" . hydra-dired-quick-sort/body)))


  ;; Show git info in dired
  (use-package dired-git-info
    :bind (:map dired-mode-map
           (")" . dired-git-info-mode)))

  ;; Allow rsync from dired buffers
  (use-package dired-rsync
    :bind (:map dired-mode-map
           ("C-c C-r" . dired-rsync))
    :config
    (when IS-MAC
      (setq dired-rsync-options "-az --progress"))
    )

  ;; Colorful dired
  (use-package diredfl
    :hook (dired-mode . diredfl-mode))

  ;; Shows icons
  (use-package nerd-icons-dired
    :diminish
    :when (icons-displayable-p)
    :custom-face
    (nerd-icons-dired-dir-face ((t (:inherit nerd-icons-dsilver :foreground unspecified))))
    :hook (dired-mode . nerd-icons-dired-mode)
    :config
    ;; WORKAROUND: display transparent background of icons
    ;; @see https://github.com/rainstormstudio/nerd-icons-dired/issues/1#issuecomment-2628680359
    (defun my-nerd-icons-dired--add-overlay (pos string)
      "Add overlay to display STRING at POS."
      (let ((ov (make-overlay (1- pos) pos)))
        (overlay-put ov 'nerd-icons-dired-overlay t)
        (overlay-put ov 'after-string
                     (propertize "_" 'display string))))
    (advice-add #'nerd-icons-dired--add-overlay :override #'my-nerd-icons-dired--add-overlay))


  ;; Extra Dired functionality
  ;; C-x C-q into modify mode
  (use-package dired-aux :ensure nil)
  (use-package dired-x
    :ensure nil
    :demand t
    :config
    (let ((cmd (cond (IS-MAC "open")
                     (IS-LINUX "xdg-open")
                     (IS-WINDOWS "start")
                     (t ""))))
      (setq dired-guess-shell-alist-user
            `(("\\.pdf\\'" ,cmd)
              ("\\.docx\\'" ,cmd)
              ("\\.\\(?:djvu\\|eps\\)\\'" ,cmd)
              ("\\.\\(?:jpg\\|jpeg\\|png\\|gif\\|xpm\\)\\'" ,cmd)
              ("\\.\\(?:xcf\\)\\'" ,cmd)
              ("\\.csv\\'" ,cmd)
              ("\\.tex\\'" ,cmd)
              ("\\.\\(?:mp4\\|mkv\\|avi\\|flv\\|rm\\|rmvb\\|ogv\\)\\(?:\\.part\\)?\\'" ,cmd)
              ("\\.\\(?:mp3\\|flac\\)\\'" ,cmd)
              ("\\.html?\\'" ,cmd)
              ("\\.md\\'" ,cmd))))

    (setq dired-omit-files
          (concat dired-omit-files
                  "\\|^\\.DS_Store\\'"
                  "\\|^\\.project\\(?:ile\\)?\\'"
                  "\\|^\\.\\(?:svn\\|git\\)\\'"
                  "\\|^\\.ccls-cache\\'"
                  "\\|\\(?:\\.js\\)?\\.meta\\'"
                  "\\|\\.\\(?:elc\\|o\\|pyo\\|swp\\|class\\)\\'"
                  "\\|^.vscode$\\|^.emacs.*\\'"))))


;; `find-dired' alternative using `fd'
(when (executable-find "fd")
  (use-package fd-dired))

(use-package ranger
  :after dired
  :init (setq ranger-override-dired t)
  :config
  (unless (file-directory-p image-dired-dir)
    (make-directory image-dired-dir))

  (defadvice! +dired--cleanup-header-line-a ()
    "Ranger fails to clean up `header-line-format' when it is closed, so..."
    :before #'ranger-revert
    (dolist (buffer (buffer-list))
      (when (buffer-live-p buffer)
        (with-current-buffer buffer
          (when (equal header-line-format '(:eval (ranger-header-line)))
            (setq header-line-format nil))))))

  (defadvice! +dired--cleanup-mouse1-bind-a ()
    "Ranger binds an anonymous function to mouse-1 after previewing a buffer
that prevents the user from escaping the window with the mouse. This command is
never cleaned up if the buffer already existed before ranger was initialized, so
we have to clean it up ourselves."
    :after #'ranger-setup-preview
    (when (window-live-p ranger-preview-window)
      (with-current-buffer (window-buffer ranger-preview-window)
        (local-unset-key [mouse-1]))))

  (defadvice! +dired--ranger-travel-a ()
    "Temprorary fix for this function until ralesi/ranger.el#236 gets merged."
    :override #'ranger-travel
    (interactive)
    (let ((prompt "Travel: "))
      (cond
       ((bound-and-true-p ido-mode)
        (ranger-find-file (ido-read-file-name prompt)))
       (t
        (ranger-find-file (read-file-name prompt))))))
  (setq ranger-cleanup-on-disable t
        ranger-excluded-extensions '("mkv" "iso" "mp4")
        ranger-deer-show-details t
        ranger-max-preview-size 10
        ranger-show-hidden t
        ranger-dont-show-binary t
        ranger-show-literal nil
        ranger-hide-cursor nil))

(provide 'init-dired)
;;; init-dired.el ends here
