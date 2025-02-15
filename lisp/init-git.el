;;; init-git.el ---                                  -*- lexical-binding: t; -*-

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

(defun my-transient-file (file-name)
  (expand-file-name (convert-standard-filename file-name) dotfairy-local-dir))
(setq transient-history-file (my-transient-file "transient/history.el")
      transient-values-file (my-transient-file "transient/values.el")
      transient-levels-file (my-transient-file "transient/levels.el"))

(use-package magit
  :ensure t
  :commands (+magit/quit +magit/quit-all)
  :bind
  (("C-x g" . magit-status))
  :config
  ;; modeline magit status update, But doing so isn't good for performance
  (setq auto-revert-check-vc-info t)
  (defvar +magit--stale-p nil)

  (defun +magit--revert-buffer (buffer)
    (with-current-buffer buffer
      (kill-local-variable '+magit--stale-p)
      (when buffer-file-name
        (if (buffer-modified-p (current-buffer))
            (when (bound-and-true-p vc-mode)
              (vc-refresh-state)
              (force-mode-line-update))
          (revert-buffer t t t)))))

;;;###autoload
  (defun +magit-mark-stale-buffers-h ()
    "Revert all visible buffers and mark buried buffers as stale.
Stale buffers are reverted when they are switched to, assuming they haven't been
modified."
    (dolist (buffer (buffer-list))
      (when (buffer-live-p buffer)
        (if (get-buffer-window buffer)
            (+magit--revert-buffer buffer)
          (with-current-buffer buffer
            (setq-local +magit--stale-p t))))))
  ;;;###autoload
  (defun +magit/quit (&optional kill-buffer)
    "Bury the current magit buffer.
If KILL-BUFFER, kill this buffer instead of burying it.
If the buried/killed magit buffer was the last magit buffer open for this repo,
kill all magit buffers for this repo."
    (interactive "P")
    (let ((topdir (magit-toplevel)))
      (funcall magit-bury-buffer-function kill-buffer)
      (or (cl-find-if (lambda (win)
                        (with-selected-window win
                          (and (derived-mode-p 'magit-mode)
                               (equal magit--default-directory topdir))))
                      (window-list))
          (+magit/quit-all))))

;;;###autoload
  (defun +magit/quit-all ()
    "Kill all magit buffers for the current repository."
    (interactive)
    (mapc #'+magit--kill-buffer (magit-mode-get-buffers))
    (+magit-mark-stale-buffers-h))

  (defun +magit--kill-buffer (buf)
    "TODO"
    (when (and (bufferp buf) (buffer-live-p buf))
      (let ((process (get-buffer-process buf)))
        (if (not (processp process))
            (kill-buffer buf)
          (with-current-buffer buf
            (if (process-live-p process)
                (run-with-timer 5 nil #'+magit--kill-buffer buf)
              (kill-process process)
              (kill-buffer buf)))))))

  (after! vc-annotate
    ;; Clean up after itself
    (define-key vc-annotate-mode-map [remap quit-window] #'kill-current-buffer))

  ;; Access Git forges from Magit
  ;; see config: https://magit.vc/manual/ghub/Storing-a-Token.html#Storing-a-Token
  ;; writting like as gitlib.com:
  ;; echo "machine gitlab.com/api/v4 login $YOU_AUTH_NAME^forge password $YOU_AUTH_TOKEN" ~/.authinfo
  (use-package forge
    :demand t
    :defines forge-topic-list-columns
    :commands forge-create-pullreq forge-create-issue
    :init (setq forge-topic-list-columns
                '(("#" 5 t (:right-align t) number nil)
                  ("Title" 60 t nil title  nil)
                  ("State" 6 t nil state nil)
                  ("Updated" 10 t nill updated nil)))
    :preface
    (setq forge-add-default-bindings (not (fboundp 'evil-mode)))
    :config
    (require 'emacsql-sqlite)
    (setq forge-database-file (concat dotfairy-cache-dir "forge/forge-database.sqlite"))
    ;; All forge list modes are derived from `forge-topic-list-mode'
    (map! :map forge-topic-list-mode-map :n "q" #'kill-current-buffer)
    (when (not forge-add-default-bindings)
      (map! :map magit-mode-map [remap magit-browse-thing] #'forge-browse
            :map magit-remote-section-map [remap magit-browse-thing] #'forge-browse-remote
            :map magit-branch-section-map [remap magit-browse-thing] #'forge-browse-branch))

    (use-package code-review
      :after magit
      :init
      (setq code-review-db-database-file (concat dotfairy-cache-dir "code-review/code-review-db-file.sqlite")
            code-review-log-file (concat dotfairy-cache-dir "code-review/code-review-error.log")
            code-review-auth-login-marker 'forge
            code-review-log-raw-request-responses t
            code-review-download-dir (expand-file-name "code-review/" dotfairy-cache-dir))

      (defun +magit/start-code-review (arg)
        (interactive "P")
        (call-interactively
         (let* ((pullreq (or (forge-pullreq-at-point) (forge-current-topic)))
                (repo    (forge-get-repository pullreq))
                (githost (concat (oref repo githost) "/api")))
           (when (forge-gitlab-repository-p repo)
             (setq-default code-review-gitlab-host githost
                           code-review-gitlab-graphql-host githost))
           (if (or arg (not (featurep 'forge)))
               #'code-review-start
             #'code-review-forge-pr-at-point))))
      (transient-append-suffix 'magit-merge "i"
        '("y" "Review pull request" +magit/start-code-review))
      (after! forge
        (transient-append-suffix 'forge-dispatch "c u"
          '("c r" "Review pull request" +magit/start-code-review))))

    (with-eval-after-load 'evil-collection-magit
      (defvar evil-collection-magit-use-z-for-folds t)
      ;; q is enough; ESC is way too easy for a vimmer to accidentally press,
      ;; especially when traversing modes in magit buffers.
      (evil-define-key* 'normal magit-status-mode-map [escape] nil)
      (after! code-review
        (map! :map code-review-mode-map
              :n "r" #'code-review-transient-api
              :n "RET" #'code-review-comment-add-or-edit))

      ;; Some extra vim-isms I thought were missing from upstream
      (evil-define-key* '(normal visual) magit-mode-map
        "*"  #'magit-worktree
        "zt" #'evil-scroll-line-to-top
        "zz" #'evil-scroll-line-to-center
        "zb" #'evil-scroll-line-to-bottom
        "g=" #'magit-diff-default-context
        "gi" #'forge-jump-to-issues
        "gm" #'forge-jump-to-pullreqs)

      ;; Fix these keybinds because they are blacklisted
      ;; REVIEW There must be a better way to exclude particular evil-collection
      ;;        modules from the blacklist.
      (map! (:map magit-mode-map
             :nv "q" #'+magit/quit
             :nv "Q" #'+magit/quit-all
             :nv "]" #'magit-section-forward-sibling
             :nv "[" #'magit-section-backward-sibling
             :nv "gr" #'magit-refresh
             :nv "gR" #'magit-refresh-all)
            (:map magit-status-mode-map
             :nv "gz" #'magit-refresh)
            (:map magit-diff-mode-map
             :nv "gd" #'magit-jump-to-diffstat-or-diff)
            ;; Don't open recursive process buffers
            (:map magit-process-mode-map
             :nv "`" #'ignore)))))

;; Walk through git revisions of a file
(use-package git-timemachine
  :custom-face
  (git-timemachine-minibuffer-author-face ((t (:inherit success :foreground unspecified))))
  (git-timemachine-minibuffer-detail-face ((t (:inherit warning :foreground unspecified))))
  :bind (:map vc-prefix-map
         ("t" . git-timemachine))
  :hook ((git-timemachine-mode . (lambda ()
                                   "Improve `git-timemachine' buffers."
                                   ;; Display different colors in mode-line
                                   (if (facep 'mode-line-active)
                                       (face-remap-add-relative 'mode-line-active 'custom-state)
                                     (face-remap-add-relative 'mode-line 'custom-state))

                                   ;; Highlight symbols in elisp
                                   (and (derived-mode-p 'emacs-lisp-mode)
                                        (fboundp 'highlight-defined-mode)
                                        (highlight-defined-mode t))

                                   ;; Display line numbers
                                   (and (derived-mode-p 'prog-mode 'yaml-mode)
                                        (fboundp 'display-line-numbers-mode)
                                        (display-line-numbers-mode t))))
         (before-revert . (lambda ()
                            (when (bound-and-true-p git-timemachine-mode)
                              (user-error "Cannot revert the timemachine buffer")))))
  :config
  (after! git-timemachine
    ;; Sometimes I forget `git-timemachine' is enabled in a buffer, so instead of
    ;; showing revision details in the minibuffer, show them in
    ;; `header-line-format', which has better visibility.
    (setq git-timemachine-show-minibuffer-details t)

    ;; TODO PR this to `git-timemachine'
    (defadvice! +vc-support-git-timemachine-a (fn)
      "Allow `browse-at-remote' commands in git-timemachine buffers to open that
file in your browser at the visited revision."
      :around #'browse-at-remote-get-url
      (if git-timemachine-mode
          (let* ((start-line (line-number-at-pos (min (region-beginning) (region-end))))
                 (end-line (line-number-at-pos (max (region-beginning) (region-end))))
                 (remote-ref (browse-at-remote--remote-ref buffer-file-name))
                 (remote (car remote-ref))
                 (ref (car git-timemachine-revision))
                 (relname
                  (file-relative-name
                   buffer-file-name (expand-file-name (vc-git-root buffer-file-name))))
                 (target-repo (browse-at-remote--get-url-from-remote remote))
                 (remote-type (browse-at-remote--get-remote-type target-repo))
                 (repo-url (cdr target-repo))
                 (url-formatter (browse-at-remote--get-formatter 'region-url remote-type)))
            (unless url-formatter
              (error (format "Origin repo parsing failed: %s" repo-url)))
            (funcall url-formatter repo-url ref relname
                     (if start-line start-line)
                     (if (and end-line (not (equal start-line end-line))) end-line)))
        (funcall fn)))

    (defadvice! +vc-update-header-line-a (revision)
      "Show revision details in the header-line, instead of the minibuffer.

Sometimes I forget `git-timemachine' is enabled in a buffer. Putting revision
info in the `header-line-format' is a more visible indicator."
      :override #'git-timemachine--show-minibuffer-details
      (let* ((date-relative (nth 3 revision))
             (date-full (nth 4 revision))
             (author (if git-timemachine-show-author (concat (nth 6 revision) ": ") ""))
             (sha-or-subject (if (eq git-timemachine-minibuffer-detail 'commit) (car revision) (nth 5 revision))))
        (setq header-line-format
              (format "%s%s [%s (%s)]"
                      (propertize author 'face 'git-timemachine-minibuffer-author-face)
                      (propertize sha-or-subject 'face 'git-timemachine-minibuffer-detail-face)
                      date-full date-relative))))

    ;; HACK: `delay-mode-hooks' suppresses font-lock-mode in later versions of
    ;;   Emacs, so git-timemachine buffers end up unfontified.
    (add-hook 'git-timemachine-mode-hook #'font-lock-mode)

    (after! evil
      ;; Rehash evil keybindings so they are recognized
      (add-hook 'git-timemachine-mode-hook #'evil-normalize-keymaps))

    (when (featurep 'magit-mode)
      (add-transient-hook! #'git-timemachine-blame (require 'magit-blame)))

    (map! :map git-timemachine-mode-map
          :n "C-p" #'git-timemachine-show-previous-revision
          :n "C-n" #'git-timemachine-show-next-revision
          :n "gb"  #'git-timemachine-blame
          :n "gtc" #'git-timemachine-show-commit)))

;; Pop up last commit information of current line
(use-package git-messenger
  :bind (:map vc-prefix-map
         ("p" . git-messenger:popup-message)
         :map git-messenger-map
         ("m" . git-messenger:copy-message))
  :init (setq git-messenger:show-detail t
              git-messenger:use-magit-popup t)
  :config
  (with-no-warnings
    (with-eval-after-load 'hydra
      (defhydra git-messenger-hydra (:color blue)
        ("s" git-messenger:popup-show "show")
        ("c" git-messenger:copy-commit-id "copy hash")
        ("m" git-messenger:copy-message "copy message")
        ("," (catch 'git-messenger-loop (git-messenger:show-parent)) "go parent")
        ("q" git-messenger:popup-close "quit")))

    (defun my-git-messenger:format-detail (vcs commit-id author message)
      (if (eq vcs 'git)
          (let ((date (git-messenger:commit-date commit-id))
                (colon (propertize ":" 'face 'font-lock-comment-face)))
            (concat
             (format "%s%s %s \n%s%s %s\n%s  %s %s \n"
                     (propertize "Commit" 'face 'font-lock-keyword-face) colon
                     (propertize (substring commit-id 0 8) 'face 'font-lock-comment-face)
                     (propertize "Author" 'face 'font-lock-keyword-face) colon
                     (propertize author 'face 'font-lock-string-face)
                     (propertize "Date" 'face 'font-lock-keyword-face) colon
                     (propertize date 'face 'font-lock-string-face))
             (propertize (make-string 38 ?─) 'face 'font-lock-comment-face)
             message
             (propertize "\nPress q to quit" 'face '(:inherit (font-lock-comment-face italic)))))
        (git-messenger:format-detail vcs commit-id author message)))

    (defun my-git-messenger:popup-message ()
      "Popup message with `posframe', `pos-tip', `lv' or `message', and dispatch actions with `hydra'."
      (interactive)
      (let* ((vcs (git-messenger:find-vcs))
             (file (buffer-file-name (buffer-base-buffer)))
             (line (line-number-at-pos))
             (commit-info (git-messenger:commit-info-at-line vcs file line))
             (commit-id (car commit-info))
             (author (cdr commit-info))
             (msg (git-messenger:commit-message vcs commit-id))
             (popuped-message (if (git-messenger:show-detail-p commit-id)
                                  (my-git-messenger:format-detail vcs commit-id author msg)
                                (cl-case vcs
                                  (git msg)
                                  (svn (if (string= commit-id "-")
                                           msg
                                         (git-messenger:svn-message msg)))
                                  (hg msg)))))
        (setq git-messenger:vcs vcs
              git-messenger:last-message msg
              git-messenger:last-commit-id commit-id)
        (run-hook-with-args 'git-messenger:before-popup-hook popuped-message)
        (git-messenger-hydra/body)
        (cond ((and (fboundp 'posframe-workable-p) (posframe-workable-p))
               (let ((buffer-name "*git-messenger*"))
                 (posframe-show buffer-name
                                :string (concat (propertize "\n" 'face '(:height 0.3))
                                                popuped-message
                                                "\n"
                                                (propertize "\n" 'face '(:height 0.3)))
                                :left-fringe 8
                                :right-fringe 8
                                :max-width (round (* (frame-width) 0.62))
                                :max-height (round (* (frame-height) 0.62))
                                :internal-border-width 1
                                ;; :internal-border-color (face-background 'posframe-border nil t)
                                :background-color (face-background 'tooltip nil t))
                 (unwind-protect
                     (push (read-event) unread-command-events)
                   (posframe-delete buffer-name))))
              ((and (fboundp 'pos-tip-show) (display-graphic-p))
               (pos-tip-show popuped-message))
              ((fboundp 'lv-message)
               (lv-message popuped-message)
               (unwind-protect
                   (push (read-event) unread-command-events)
                 (lv-delete-window)))
              (t (message "%s" popuped-message)))
        (run-hook-with-args 'git-messenger:after-popup-hook popuped-message)))
    (advice-add #'git-messenger:popup-close :override #'ignore)
    (advice-add #'git-messenger:popup-message :override #'my-git-messenger:popup-message)))

;; Resolve diff3 conflicts
(use-package smerge-mode
  :ensure t
  :diminish
  :pretty-hydra
  ((:title (pretty-hydra-title "Smerge" 'octicon "nf-oct-diff")
    :color pink :quit-key ("q" "C-g"))
   ("Move"
    (("n" (progn (smerge-vc-next-conflict) (recenter-top-bottom (/ (window-height) 8))) "recenter next")
     ("N" smerge-next "next")
     ("p" smerge-prev "previous")
     ("g" (progn (goto-char (point-min)) (smerge-next)) "goto first")
     ("G" (progn (goto-char (point-max)) (smerge-prev)) "goto last"))
    "Keep"
    (("b" smerge-keep-base "base")
     ("u" smerge-keep-upper "mine")
     ("o" smerge-keep-lower "other")
     ("a" smerge-keep-all "all")
     ("RET" smerge-keep-current "current")
     ("C-m" smerge-keep-current "current"))
    "Diff"
    (("<" smerge-diff-base-upper "upper/base")
     ("=" smerge-diff-upper-lower "upper/lower")
     (">" smerge-diff-base-lower "base/lower")
     ("R" smerge-refine "refine")
     ("E" smerge-ediff "ediff"))
    "Other"
    (("C" smerge-combine-with-next "combine")
     ("r" smerge-resolve "resolve")
     ("k" smerge-kill-current "kill")
     ("ZZ" (lambda ()
             (interactive)
             (save-buffer)
             (bury-buffer))
      "Save and bury buffer" :exit t))))
  :config (map! :map smerge-mode-map
                :localleader
                "n" #'smerge-next
                "p" #'smerge-prev
                "r" #'smerge-resolve
                "a" #'smerge-keep-all
                "b" #'smerge-keep-base
                "o" #'smerge-keep-lower
                "l" #'smerge-keep-lower
                "m" #'smerge-keep-upper
                "u" #'smerge-keep-upper
                "E" #'smerge-ediff
                "C" #'smerge-combine-with-next
                "R" #'smerge-refine
                "C-m" #'smerge-keep-current
                (:prefix "="
                 "<" #'smerge-diff-base-upper
                 ">" #'smerge-diff-base-lower
                 "=" #'smerge-diff-upper-lower)
                :m "v" #'smerge-mode-hydra/body)

  :hook ((find-file . (lambda ()
                        (unless (bound-and-true-p smerge-mode)
                          (save-excursion
                            (goto-char (point-min))
                            (when (re-search-forward "^<<<<<<< " nil t)
                              (smerge-mode 1))))))
         (magit-diff-visit-file . (lambda ()
                                    (when smerge-mode
                                      (smerge-mode-hydra/body))))))

;; Open github/gitlab/bitbucket page
(use-package browse-at-remote
  :bind (:map vc-prefix-map
         ("." . browse-at-remote)))

;; Git related modes
(use-package git-modes)

(add-hook! 'git-commit-setup-hook
  (defun +vc-start-in-insert-state-maybe-h ()
    "Start git-commit-mode in insert state if in a blank commit message,
-otherwise in default state."
    (when (and (bound-and-true-p evil-local-mode)
               (not (evil-emacs-state-p))
               (bobp) (eolp))
      (evil-insert-state))))

(provide 'init-git)
;;; init-git.el ends here
