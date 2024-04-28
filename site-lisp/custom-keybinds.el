;;; custom-keybinds.el ---                                   -*- lexical-binding: t; -*-

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
(require 'init-funcs)

;; persp-mode and projectile in different prefixes
(setq persp-keymap-prefix (kbd "C-c w"))
(after! projectile
  (define-key projectile-mode-map (kbd "C-x p") 'projectile-command-map))

(autoload 'org-capture-goto-target "org-capture" nil t)
(map! :leader
  (:prefix-map ("a" . "appliction")
   (:prefix ("C" . "Calendar")
    :desc "Open calendar"              "o" #'+calendar/open-calendar
    :desc "Open git calendar"          "g" #'cfw:git-open-calendar)
   (:prefix ("c" . "Command log")
    :desc "Enable command log mode"    "e" #'command-log-mode
    :desc "Toggle command log buffer"  "g" #'clm/toggle-command-log-buffer)
   :desc "Kubernetes Overview"                               "b"       #'kubernetes-overview
   :desc "Docker Management"                                 "d"       #'docker
   (:prefix ("m" . "Music Player")
    :desc "Music Player"                        "b" #'bongo
    :desc "Music Player for mpd"                "m" #'mpc
    :desc "Music Player for mingus"             "M" #'mingus)
   :desc "Reading"                             "r" #'olivetti-mode
   :desc "Quick Run"                           "R" #'quickrun-hydra/body)

  (:prefix-map ("b" . "buffers")
   :desc "Kill all buffers"                    "a" #'dotfairy/kill-all-buffers
   :desc "Kill this buffer in all windows"     "A" #'dotfairy/kill-this-buffer-in-all-windows
   :desc "Switch to buffer"                    "b" #'switch-to-buffer
   :desc "Kill buffer"                         "k" #'kill-buffer
   :desc "Kill buried buffers"                 "K" #'dotfairy/kill-buried-buffers
   :desc "New buffer"                          "n" #'+default/new-buffer
   :desc "Save and kill buffer"                "s" #'dotfairy/save-and-kill-buffer
   :desc "Kill other buffers"                  "o" #'dotfairy/kill-other-buffers
   :desc "kill matching buffers"               "m" #'dotfairy/kill-matching-buffers
   )
  ;;; <leader> c --- code
  (:prefix-map ("c" . "coding")
   :desc "LSP Execute code action"             "a" #'lsp-execute-code-action
   :desc "LSP Organize imports"                "o" #'lsp-organize-imports
   :desc "LSP Rename"                          "r" #'lsp-rename
   :desc "Symbols"                             "S" #'lsp-treemacs-symbols
   (:when (featurep 'vertico)
    :desc "Jump to symbol in current workspace" "j"   #'consult-lsp-symbols
    :desc "Jump to symbol in any workspace"     "J"   (cmd!! #'consult-lsp-symbols 'all-workspaces))
   (:when (featurep 'treemacs)
    :desc "Errors list"                         "X"   #'lsp-treemacs-errors-list
    :desc "Incoming call hierarchy"             "y"   #'lsp-treemacs-call-hierarchy
    :desc "Outgoing call hierarchy"             "Y"   (cmd!! #'lsp-treemacs-call-hierarchy t)
    :desc "References tree"                     "R"   (cmd!! #'lsp-treemacs-references t)
    :desc "Symbols"                             "S"   #'lsp-treemacs-symbols)
   :desc "LSP"                                 "l" #'+default/lsp-command-map
   :desc "Compile or Recompile"                "c" #'+default/compile
   :desc "Remember init"                       "." #'remember-init
   :desc "Remember jump"                       "," #'remember-jump
   :desc "Open newline below"                  "o" #'open-newline-below
   :desc "Open newline above"                  "O" #'open-newline-above
   :desc "Duplicate line or region below"      "D" #'duplicate-line-or-region-below
   :desc "Duplicate line or region above"      "d" #'duplicate-line-or-region-above)

  (:prefix-map ("e" . "editor")
   :desc "Hungry delete backward"              "b" #'hungry-delete-backward
   :desc "Dired change to wdired-mode"         "e" #'wdired-change-to-wdired-mode
   :desc "Hungry delete forward"               "f" #'hungry-delete-forward
   :desc "Delete trailing whitespace"          "w" #'delete-trailing-whitespace)

  ;;; <leader> f --- file
  (:prefix-map ("f" . "file")
   :desc "Open project editorconfig"   "." #'editorconfig-find-current-editorconfig
   :desc "Copy this file"              "c" #'dotfairy/copy-this-file
   :desc "Rename this file name"       "C" #'dotfairy/copy-file-name
   :desc "Find directory"              "d" #'+default/dired
   :desc "Delete this file"            "D" #'dotfairy/delete-this-file
   :desc "Find file in emacs.d"        "e" #'dotfairy/find-file-in-emacsd
   :desc "Browse in emacs.d"           "E" #'dotfairy/browse-in-emacsd
   :desc "Find file"                   "f" #'find-file
   :desc "Find file from here"         "F" #'+default/find-file-under-here
   :desc "Locate file"                 "l" #'locate
   :desc "Reload init file"            "L" #'dotfairy/reload-init-file
   :desc "Rename/move this file"       "m" #'dotfairy/move-this-file
   :desc "Rename this buffer file"     "M" #'dotfairy/rename-this-file
   :desc "Recent files"                "r" #'recentf-open-files
   :desc "Remove recent file"          "R" #'dotfairy/remove-recent-file
   :desc "Save file"                   "s" #'save-buffer
   :desc "Save file as..."             "S" #'write-file
   :desc "Sudo this file"              "u" #'dotfairy/sudo-this-file
   :desc "Sudo find file"              "U" #'dotfairy/sudo-find-file
   :desc "Open init file"              "i" #'dotfairy/open-init-file
   :desc "Open custom file"            "I" #'dotfairy/open-custom-file
   :desc "Yank file path"              "y" #'+default/yank-buffer-path
   :desc "Yank file path from project" "Y" #'+default/yank-buffer-path-relative-to-project)

  (:prefix-map ("g" . "git")
   :desc "Magit dispatch"            "/"   #'magit-dispatch
   :desc "Magit file dispatch"       "."   #'magit-file-dispatch
   :desc "Forge dispatch"            "'"   #'forge-dispatch
   :desc "Magit switch branch"       "b"   #'magit-branch-checkout
   :desc "Magit status"              "g"   #'magit-status
   :desc "Magit status here"         "G"   #'magit-status-here
   :desc "Magit file delete"         "D"   #'magit-file-delete
   :desc "Magit blame"               "B"   #'magit-blame-addition
   :desc "Magit clone"               "C"   #'magit-clone
   :desc "Magit fetch"               "F"   #'magit-fetch
   :desc "Magit buffer log"          "L"   #'magit-log-buffer-file
   :desc "Git stage this file"       "S"   #'magit-stage-buffer-file
   :desc "Git unstage this file"     "U"   #'magit-unstage-file
   :desc "Git time machine"          "t"   #'git-timemachine-toggle
   :desc "Git messager"              "m"   #'git-messenger:popup-message
   :desc "SMerge"                    "M"   #'smerge-mode-hydra/body
   (:prefix ("f" . "find")
    :desc "Find file"                 "f"   #'magit-find-file
    :desc "Find gitconfig file"       "g"   #'magit-find-git-config-file
    :desc "Find commit"               "c"   #'magit-show-commit
    :desc "Find issue"                "i"   #'forge-visit-issue
    :desc "Find pull request"         "p"   #'forge-visit-pullreq)
   (:prefix ("o" . "open in browser")
    :desc "Browse file or region"     "o"   #'browse-at-remote
    :desc "Browse remote"             "r"   #'forge-browse-remote
    :desc "Browse commit"             "c"   #'forge-browse-commit
    :desc "Browse an issue"           "i"   #'forge-browse-issue
    :desc "Browse a pull request"     "p"   #'forge-browse-pullreq
    :desc "Browse issues"             "I"   #'forge-browse-issues
    :desc "Browse pull requests"      "P"   #'forge-browse-pullreqs)
   (:prefix ("l" . "list")
    :desc "List repositories"         "r"   #'magit-list-repositories
    :desc "List submodules"           "s"   #'magit-list-submodules
    :desc "List issues"               "i"   #'forge-list-issues
    :desc "List pull requests"        "p"   #'forge-list-pullreqs
    :desc "List notifications"        "n"   #'forge-list-notifications)
   (:prefix ("c" . "create")
    :desc "Initialize repo"           "r"   #'magit-init
    :desc "Clone repo"                "R"   #'magit-clone
    :desc "Commit"                    "c"   #'magit-commit-create
    :desc "Fixup"                     "f"   #'magit-commit-fixup
    :desc "Branch"                    "b"   #'magit-branch-and-checkout
    :desc "Issue"                     "i"   #'forge-create-issue
    :desc "Pull request"              "p"   #'forge-create-pullreq)
   )

  ;;; <leader> i --- insert
  (:prefix-map ("i" . "insert")
   :desc "Emoji"                         "e" #'emojify-insert-emoji
   :desc "Snippet"                       "s" #'yas-insert-snippet
   :desc "Current file name"             "f" #'+default/insert-file-path
   :desc "Current file path"             "F" (cmd!! #'+default/insert-file-path t)
   :desc "Snippet"                       "s" #'yas-insert-snippet
   :desc "Unicode"                       "u" #'insert-char
   :desc "Unicode"                       "u" #'unicode-property-table-internal)

  (:prefix-map ("k" . "kill")
   :desc "Kill all buffers"                    "a" #'dotfairy/kill-all-buffers
   :desc "Kill this buffer in all windows"     "A" #'dotfairy/kill-this-buffer-in-all-windows
   :desc "Kill buried buffers"                 "k" #'kill-buffer

   :desc "Kill other buffers"                  "o" #'dotfairy/kill-other-buffers
   :desc "kill matching buffers"               "m" #'dotfairy/kill-matching-buffers)
  ;;; <leader> n --- notes
  (:prefix-map ("n" . "notes")
   :desc "Search notes for symbol"        "*" #'+default/search-notes-for-symbol-at-point
   :desc "Org agenda"                     "a" #'org-agenda
   :desc "Cancel current org-clock"       "C" #'org-clock-cancel
   :desc "Find file in notes"             "f" #'+default/find-in-notes
   :desc "Browse notes"                   "F" #'+default/browse-notes
   :desc "Org capture"                    "n" #'org-capture
   :desc "Goto capture"                   "N" #'org-capture-goto-target
   :desc "Org store link"                 "l" #'org-store-link
   :desc "Tags search"                    "m" #'org-tags-view
   :desc "Active org-clock"               "o" #'org-clock-goto
   :desc "Todo list"                      "t" #'org-todo-list
   :desc "View search"                    "v" #'org-search-view
   (:prefix ("r" . "roam")
    :desc "Open random node"           "a" #'org-roam-node-random
    :desc "Find node"                  "f" #'org-roam-node-find
    :desc "Find ref"                   "F" #'org-roam-ref-find
    :desc "Show graph"                 "g" #'org-roam-graph
    :desc "Insert node"                "i" #'org-roam-node-insert
    :desc "Capture to node"            "n" #'org-roam-capture
    :desc "Toggle roam buffer"         "r" #'org-roam-buffer-toggle
    :desc "Launch roam buffer"         "R" #'org-roam-buffer-display-dedicated
    :desc "Sync database"              "s" #'org-roam-db-sync
    (:prefix ("d" . "by date")
     :desc "Goto previous note"        "b" #'org-roam-dailies-goto-previous-note
     :desc "Goto date"                 "d" #'org-roam-dailies-goto-date
     :desc "Capture date"              "D" #'org-roam-dailies-capture-date
     :desc "Goto next note"            "f" #'org-roam-dailies-goto-next-note
     :desc "Goto tomorrow"             "m" #'org-roam-dailies-goto-tomorrow
     :desc "Capture tomorrow"          "M" #'org-roam-dailies-capture-tomorrow
     :desc "Capture today"             "n" #'org-roam-dailies-capture-today
     :desc "Goto today"                "t" #'org-roam-dailies-goto-today
     :desc "Capture today"             "T" #'org-roam-dailies-capture-today
     :desc "Goto yesterday"            "y" #'org-roam-dailies-goto-yesterday
     :desc "Capture yesterday"         "Y" #'org-roam-dailies-capture-yesterday
     :desc "Find directory"            "-" #'org-roam-dailies-find-directory)))
  ;;; <leader> o --- open
  "o" nil ; we need to unbind it first as Org claims this prefix
  (:prefix-map ("o" . "open")
   :desc "Browser"            "b"  #'browse-url-of-file
   :desc "Open Dired"         "d"  #'+default/dired
   :desc "New frame"          "f"  #'make-frame
   :desc "Dired"              "-"  #'dired-jump
   :desc "Docker"             "D"  #'docker
   :desc "Find file in project sidebar" "P" #'treemacs-find-file)

  ;;; <leader> p --- project
  (:prefix ("p" . "project")
   :desc "Add directory to project"        "a" #'dotfairy/add-directory-as-project
   :desc "Compile in project"              "c" #'projectile-compile-project
   :desc "Remove known project"            "d" #'projectile-remove-known-project
   :desc "Recent project files"            "r" #'projectile-recentf
   :desc "Restart current workspace"       "R" #'lsp-workspace-restart
   :desc "Find file in other project"      "F" #'dotfairy/find-file-in-other-project
   :desc "Add to workspace"                "i" #'lsp-workspace-folders-add
   :desc "Kill project buffers"            "k" #'dotfairy/kill-project-buffers
   :desc "Browse project"                  "." #'+default/browse-project
   :desc "Browse other project"            ">" #'dotfairy/browse-in-other-project
   :desc "Search project for symbol at point"  "y" #'+default/search-project-for-symbol-at-point
   :desc "Search project"                  "s" #'+default/search-project
   :desc "Search Other Project"            "S" #'+default/search-other-project
   :desc "List project todos"              "t" #'magit-todos-list
   (:when (eq dotfairy-complete 'vertico)
    :desc "Find file in project"        "f" #'+vertico/consult-fd-or-find)
   :desc "Run cmd in project root"      "!" #'projectile-run-shell-command-in-root
   :desc "Async cmd in project root"    "&" #'projectile-run-async-shell-command-in-root
   :desc "Add new project"              "A" #'projectile-add-known-project
   :desc "Switch to project buffer"     "b" #'projectile-switch-to-buffer
   :desc "Repeat last command"          "C" #'projectile-repeat-last-command
   :desc "Discover projects in folder"  "D" #'+default/discover-projects
   :desc "Edit project .dir-locals"     "e" #'projectile-edit-dir-locals
   :desc "Find file in project"         "l" #'projectile-find-file
   :desc "Configure project"            "g" #'projectile-configure-project
   :desc "Invalidate project cache"     "i" #'projectile-invalidate-cache
   :desc "Kill project buffers"         "k" #'projectile-kill-buffers
   :desc "Find sibling file"            "o" #'find-sibling-file
   :desc "Switch project"               "p" #'projectile-switch-project
   :desc "Find recent project files"    "r" #'projectile-recentf
   :desc "Run project"                  "R" #'projectile-run-project
   :desc "Save project files"           "s" #'projectile-save-project-buffers
   :desc "Test project"                 "T" #'projectile-test-project)

  ;;; <leader> q --- quit/restart
  (:prefix-map ("q" . "quit/restart")
   :desc "Delete frame"                 "f" #'delete-frame
   :desc "Clear current frame"          "F" #'dotfairy/kill-all-buffers
   :desc "Kill Emacs (and daemon)"      "K" #'save-buffers-kill-emacs
   :desc "Quit Emacs"                   "q" #'kill-emacs
   :desc "Save and quit Emacs"          "Q" #'save-buffers-kill-terminal
   )

  ;;; <leader> & --- snippets
  (:prefix-map ("&" . "snippets")
   :desc "New snippet"           "n" #'yas-new-snippet
   :desc "Insert snippet"        "i" #'yas-insert-snippet
   :desc "Find global snippet"   "/" #'yas-visit-snippet-file
   :desc "Reload snippets"       "r" #'yas-reload-all
   :desc "Read snippets name from minibuffer" "y" #'ivy-yasnippet)

  ;;; <leader> r --- remote
  (:prefix-map ("r" . "remote")
   :desc "Browse remote"              "b" #'ssh-deploy-browse-remote-base-handler
   :desc "Browse relative"            "B" #'ssh-deploy-browse-remote-handler
   :desc "Download remote"            "d" #'ssh-deploy-download-handler
   :desc "Delete local & remote"      "D" #'ssh-deploy-delete-handler
   :desc "Eshell base terminal"       "e" #'ssh-deploy-remote-terminal-eshell-base-handler
   :desc "Eshell relative terminal"   "E" #'ssh-deploy-remote-terminal-eshell-handler
   :desc "Move/rename local & remote" "m" #'ssh-deploy-rename-handler
   :desc "Open this file on remote"   "o" #'ssh-deploy-open-remote-file-handler
   :desc "Run deploy script"          "s" #'ssh-deploy-run-deploy-script-handler
   :desc "Upload local"               "u" #'ssh-deploy-upload-handler
   :desc "Upload local (force)"       "U" #'ssh-deploy-upload-handler-forced
   :desc "Diff local & remote"        "x" #'ssh-deploy-diff-handler
   :desc "Browse remote files"        "." #'ssh-deploy-browse-remote-handler
   :desc "Detect remote changes"      ">" #'ssh-deploy-remote-changes-handler)

  ;;; <leader> s --- search
  (:prefix-map ("s" . "search")
   :desc "Internet Search Engine"       "/" #'webjump
   :desc "Search buffer"                "b"
   (cond ((featurep 'vertico)   #'consult-line)
         ((featurep 'ivy)       #'swiper))
   :desc "Search all open buffers"      "B"
   (cond ((featurep 'vertico)   (cmd!! #'consult-line-multi 'all-buffers))
         ((featurep 'ivy)       #'swiper-all))
   :desc "Search current directory"     "d" #'+default/search-cwd
   :desc "Search other directory"       "D" #'+default/search-other-cwd
   :desc "Jump to visible link"         "l" #'link-hint-open-link
   :desc "Jump to link"                 "L" #'ffap-menu
   :desc "Jump to bookmark"             "m" #'bookmark-jump
   :desc "Jump to bookmark"             "m" #'bookmark-jump
   :desc "rg menu"                      "M" #'rg-menu
   :desc "Search project"               "p" #'+default/search-project
   :desc "Search other project"         "P" #'+default/search-other-project
   :desc "Search buffer"                "s" #'+default/search-buffer
   :desc "Search buffer for thing at point" "S"
   (cond ((featurep 'vertico)   #'+vertico/search-symbol-at-point)
         ((featurep 'ivy)       #'swiper-isearch-thing-at-point))
   :desc "Undo history"                 "u" #'vundo)

  ;;; <leader> t --- toggle
  (:prefix-map ("t" . "toggle")
   :desc "Flymake"                      "f" #'flymake-mode
   :desc "Indent style"                 "I" #'dotfairy/toggle-indent-style
   :desc "Line numbers"                 "l" #'dotfairy/toggle-line-numbers
   :desc "Read-only mode"               "r" #'read-only-mode
   :desc "Visible mode"                 "v" #'visible-mode
   :desc "Soft line wrapping"           "w" #'+word-wrap-mode)

  ;;; <leader> w --- workspaces/windows
  (:prefix-map ("w" . "workspaces/windows")
   (:prefix-map ("f" . "frame")
    :desc "Frame maximized"              "f" #'dotfairy/frame-maximize
    :desc "Frame fullscreen"             "F" #'toggle-frame-fullscreen
    :desc "Frame restore"                "r" #'dotfairy/frame-restore
    :desc "Frame bottom half"            "j" #'dotfairy/frame-bottom-half
    :desc "Frame top half"               "k" #'dotfairy/frame-top-half
    :desc "Frame left half"              "h" #'dotfairy/frame-left-half
    :desc "Frame right half"             "l" #'dotfairy/frame-right-half)
   :desc "Management windows"           "m" #'ace-window-hydra/body
   :desc "Undo window config"           "u" #'winner-undo
   :desc "Redo window config"           "U" #'winner-redo))

(provide 'custom-keybinds)
;;; custom-keybinds.el ends here
