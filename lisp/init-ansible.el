;;; init-ansible.el --- auto deploy  -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2024 b40yd
;;
;; Author: b40yd <bb.qnyd@gmail.com>
;; Maintainer: b40yd <bb.qnyd@gmail.com>
;; Created: November 04, 2024
;; Modified: November 04, 2024
;; Version: 0.0.1
;; Keywords:
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:



(use-package ansible
  :commands ansible-auto-decrypt-encrypt
  :init
  (put 'ansible-vault-password-file 'safe-local-variable #'stringp)
  :config
  (setq ansible-section-face 'font-lock-variable-name-face
        ansible-task-label-face 'font-lock-doc-face)
  (map! :map ansible-key-map
        :localleader
        :desc "Decrypt buffer"          "d" #'ansible-decrypt-buffer
        :desc "Encrypt buffer"          "e" #'ansible-encrypt-buffer
        :desc "Look up in Ansible docs" "h" #'ansible-doc))

(use-package ansible-doc
  :config
  (after! ansible-doc
    (set-evil-initial-state! '(ansible-doc-module-mode) 'emacs)))


(use-package jinja2-mode
  :mode "\\.j2\\'"
  :config
  ;; The default behavior is to reindent the whole buffer on save. This is
  ;; disruptive and imposing. There are indentation commands available; the user
  ;; can decide when they want their code reindented.
  (setq jinja2-enable-indent-on-save nil))

(provide 'init-ansible)
;;; init-ansible.el ends here
