;;; init-funcs.el ---                                   -*- lexical-binding: t; -*-

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
(require 'cl-lib)
(require 'init-const)
(require 'init-custom)
(require 'init-proxy)
(require 'init-files)

;;;###autoload
(defmacro plist-put! (plist &rest rest)
  "Set each PROP VALUE pair in REST to PLIST in-place."
  `(cl-loop for (prop value)
            on (list ,@rest) by #'cddr
            do ,(if (symbolp plist)
                    `(setq ,plist (plist-put ,plist prop value))
                  `(plist-put ,plist prop value))))

;;;###autoload
(defmacro plist-delete! (plist prop)
  "Delete PROP from PLIST in-place."
  `(setq ,plist (dotfairy-plist-delete ,plist ,prop)))

;;;###autoload
(defun dotfairy-plist-get (plist prop &optional nil-value)
  "Return PROP in PLIST, if it exists. Otherwise NIL-VALUE."
  (if-let (val (plist-member plist prop))
      (cadr val)
    nil-value))

;;;###autoload
(defun dotfairy-plist-merge (from-plist to-plist)
  "Non-destructively merge FROM-PLIST onto TO-PLIST"
  (let ((from-plist (copy-sequence from-plist))
        (to-plist (copy-sequence to-plist)))
    (while from-plist
      (cl-callf plist-put to-plist (pop from-plist) (pop from-plist)))
    to-plist))

;;;###autoload
(defun dotfairy-plist-delete-nil (plist)
  "Delete `nil' properties from a copy of PLIST."
  (let (p)
    (while plist
      (if (car plist)
          (plist-put! p (car plist) (nth 1 plist)))
      (setq plist (cddr plist)))
    p))

;;;###autoload
(defun dotfairy-plist-delete (plist &rest props)
  "Delete PROPS from a copy of PLIST."
  (let (p)
    (while plist
      (if (not (memq (car plist) props))
          (plist-put! p (car plist) (nth 1 plist)))
      (setq plist (cddr plist)))
    p))

;;;###autoload
(defun dotfairy-plist-keys (plist)
  "Return the keys in PLIST."
  (let (keys)
    (while plist
      (push (car plist) keys)
      (setq plist (cddr plist)))
    keys))

;;;###autoload
(defun dotfairy-plist-values (plist)
  "Return the values in PLIST."
  (let (keys)
    (while plist
      (push (cadr plist) keys)
      (setq plist (cddr plist)))
    keys))
(defun dotfairy--theme-name (theme)
  "Return internal THEME name."
  (or (alist-get theme dotfairy-theme-alist) theme 'doom-one))

(defun dotfairy--load-theme (theme)
  "Disable others and enable new one."
  (when theme
    (mapc #'disable-theme custom-enabled-themes)
    (load-theme theme t)))

(defun dotfairy-load-theme (theme &optional no-save)
  "Load color THEME. Save to `custom-file' if NO-SAVE is nil."
  ;; Set option
  (dotfairy-set-variable 'dotfairy-theme theme no-save)
  (dotfairy--load-theme (dotfairy--theme-name theme)))

(defun byte-comsdpile-elpa ()
  "Compile packages in elpa directory. Useful if you switch Emacs versions."
  (interactive)
  (if (fboundp 'async-byte-recompile-directory)
      (async-byte-recompile-directory package-user-dir)
    (byte-recompile-directory package-user-dir 0 t)))
(defun byte-compile-site-lisp ()
  "Compile packages in site-lisp directory."
  (interactive)
  (let ((dir (locate-user-emacs-file "site-lisp")))
    (if (fboundp 'async-byte-recompile-directory)
        (async-byte-recompile-directory dir)
      (byte-recompile-directory dir 0 t))))

(defun native-compile-elpa ()
  "Native-compile packages in elpa directory."
  (interactive)
  (if (fboundp 'native-compile-async)
      (native-compile-async package-user-dir t)))

(defun native-compile-site-lisp ()
  "Native compile packages in site-lisp directory."
  (interactive)
  (let ((dir (locate-user-emacs-file "site-lisp")))
    (if (fboundp 'native-compile-async)
        (native-compile-async dir t))))
;; Font
(defun font-installed-p (font-name)
  "Check if font with FONT-NAME is available."
  (find-font (font-spec :name font-name)))

(defun icons-displayable-p ()
  "Return non-nil if `all-the-icons' is displayable."
  (and display-icon
       (or (featurep 'nerd-icons)
           (require 'nerd-icons nil t))))

(defun make-custom-directory()
  "Create custom directory."
  (if (not (file-directory-p dotfairy-local-dir))
      (make-directory dotfairy-local-dir))
  ;; (if (not (file-directory-p dotfairy-org-dir))
  ;;     (make-directory dotfairy-org-dir))
  ;; (if (not (file-directory-p (concat dotfairy-org-dir "roam/")))
  ;;     (make-directory (concat dotfairy-org-dir "roam/")))
  (if (not (file-directory-p dotfairy-etc-dir))
      (make-directory dotfairy-etc-dir))
  (if (not (file-directory-p dotfairy-private-dir))
      (make-directory dotfairy-private-dir))
  (if (not (file-directory-p dotfairy-cache-dir))
      (make-directory dotfairy-cache-dir)))

(defun dotfairy-set-variable (variable value &optional no-save)
  "Set the VARIABLE to VALUE, and return VALUE.
Save to option if NO-SAVE is nil."
  (customize-set-variable variable value)
  (when (and (not no-save)
             (file-writable-p custom-file))
    (with-temp-buffer
      (insert-file-contents custom-file)
      (goto-char (point-min))
      (while (re-search-forward
              (format "^[\t ]*[;]*[\t ]*(setq %s .*)" variable)
              nil t)
        (replace-match (format "(setq %s '%s)" variable value) nil nil))
      (write-region nil nil custom-file)
      (message "Saved %s (%s) to %s" variable value custom-file))))

;; Pakcage repository (ELPA)
(defun set-package-archives (archives &optional refresh async no-save)
  "Set the package archives (ELPA).
REFRESH is non-nil, will refresh archive contents.
ASYNC specifies whether to perform the downloads in the background.
Save to `custom-file' if NO-SAVE is nil."
  (interactive
   (list
    (intern (completing-read "Select package archives: "
                             (mapcar #'car dotfairy-package-archives-alist)))))
  ;; Set option
  (dotfairy-set-variable 'dotfairy-package-archives archives no-save)

  ;; Refresh if need
  (and refresh (package-refresh-contents async))

  (message "Set package archives to `%s'" archives))
(defalias 'dotfairy-set-package-archives #'set-package-archives)

;; Refer to https://emacs-china.org/t/elpa/11192
(defun dotfairy-test-package-archives (&optional no-chart)
  "Test connection speed of all package archives and display on chart.
Not displaying the chart if NO-CHART is non-nil.
Return the fastest package archive."
  (interactive)
  (let* ((durations (mapcar
                     (lambda (pair)
                       (let ((url (concat (cdr (nth 2 (cdr pair)))
                                          "archive-contents"))
                             (start (current-time)))
                         (message "Fetching %s..." url)
                         (ignore-errors
                           (url-copy-file url null-device t))
                         (float-time (time-subtract (current-time) start))))
                     dotfairy-package-archives-alist))
         (fastest (car (nth (cl-position (apply #'min durations) durations)
                            dotfairy-package-archives-alist))))

    ;; Display on chart
    (when (and (not no-chart)
               (require 'chart nil t)
               (require 'url nil t))
      (chart-bar-quickie
       'vertical
       "Speed test for the ELPA mirrors"
       (mapcar (lambda (p) (symbol-name (car p))) dotfairy-package-archives-alist)
       "ELPA"
       (mapcar (lambda (d) (* 1e3 d)) durations) "ms"))

    (message "%s is the fastest package archive" fastest)

    ;; Return the fastest
    fastest))

;; Dos2Unix/Unix2Dos
(defun dos2unix ()
  "Convert the current buffer to UNIX file format."
  (interactive)
  (set-buffer-file-coding-system 'undecided-unix nil))

(defun unix2dos ()
  "Convert the current buffer to DOS file format."
  (interactive)
  (set-buffer-file-coding-system 'undecided-dos nil))

;;;###autoload
(defun dotfairy/toggle-indent-style ()
  "Switch between tabs and spaces indentation style in the current buffer."
  (interactive)
  (setq indent-tabs-mode (not indent-tabs-mode))
  (message "Indent style changed to %s" (if indent-tabs-mode "tabs" "spaces")))

(defvar editorconfig-lisp-use-default-indent)
;;;###autoload
(defun dotfairy/set-indent-width (width)
  "Change the indentation size to WIDTH of the current buffer.
The effectiveness of this command is significantly improved if you have
editorconfig or dtrt-indent installed."
  (interactive
   (list (if (integerp current-prefix-arg)
             current-prefix-arg
           (read-number "New indent size: "))))
  (setq tab-width width)
  (setq-local standard-indent width)
  (cond ((require 'editorconfig nil t)
         (let (editorconfig-lisp-use-default-indent)
           (editorconfig-set-indentation nil width)))
        ((require 'dtrt-indent nil t)
         (when-let (var (nth 2 (assq major-mode dtrt-indent-hook-mapping-list)))
           (set var width))))
  (message "Changed indentation to %d" width))

(defmacro letf! (bindings &rest body)
  "Temporarily rebind function, macros, and advice in BODY.

Intended as syntax sugar for `cl-letf', `cl-labels', `cl-macrolet', and
temporary advice (`define-advice').

BINDINGS is either:

  A list of (PLACE VALUE) bindings as `cl-letf*' would accept.
  A list of, or a single, `defun', `defun*', `defmacro', or `defadvice' forms.

The def* forms accepted are:

  (defun NAME (ARGS...) &rest BODY)
    Defines a temporary function with `cl-letf'
  (defun* NAME (ARGS...) &rest BODY)
    Defines a temporary function with `cl-labels' (allows recursive
    definitions).
  (defmacro NAME (ARGS...) &rest BODY)
    Uses `cl-macrolet'.
  (defadvice FUNCTION WHERE ADVICE)
    Uses `advice-add' (then `advice-remove' afterwards).
  (defadvice FUNCTION (HOW LAMBDA-LIST &optional NAME DEPTH) &rest BODY)
    Defines temporary advice with `define-advice'."
  (declare (indent defun))
  (setq body (macroexp-progn body))
  (when (memq (car bindings) '(defun defun* defmacro defadvice))
    (setq bindings (list bindings)))
  (dolist (binding (reverse bindings) body)
    (let ((type (car binding))
          (rest (cdr binding)))
      (setq
       body (pcase type
              (`defmacro `(cl-macrolet ((,@rest)) ,body))
              (`defadvice
                  (if (keywordp (cadr rest))
                      (cl-destructuring-bind (target where fn) rest
                        `(when-let (fn ,fn)
                           (advice-add ,target ,where fn)
                           (unwind-protect ,body (advice-remove ,target fn))))
                    (let* ((fn (pop rest))
                           (argspec (pop rest)))
                      (when (< (length argspec) 3)
                        (setq argspec
                              (list (nth 0 argspec)
                                    (nth 1 argspec)
                                    (or (nth 2 argspec) (gensym (format "%s-a" (symbol-name fn)))))))
                      (let ((name (nth 2 argspec)))
                        `(progn
                           (define-advice ,fn ,argspec ,@rest)
                           (unwind-protect ,body
                             (advice-remove #',fn #',name)
                             ,(if name `(fmakunbound ',name))))))))
              (`defun
                  `(cl-letf ((,(car rest) (symbol-function #',(car rest))))
                     (ignore ,(car rest))
                     (cl-letf (((symbol-function #',(car rest))
                                (lambda! ,(cadr rest) ,@(cddr rest))))
                       ,body)))
              (`defun*
                  `(cl-labels ((,@rest)) ,body))
              (_
               (when (eq (car-safe type) 'function)
                 (setq type (list 'symbol-function type)))
               (list 'cl-letf (list (cons type rest)) body)))))))

;;; Closure factories
(defmacro lambda! (arglist &rest body)
  "Returns (cl-function (lambda ARGLIST BODY...))
The closure is wrapped in `cl-function', meaning ARGLIST will accept anything
`cl-defun' will. Implicitly adds `&allow-other-keys' if `&key' is present in
ARGLIST."
  (declare (indent defun) (doc-string 1) (pure t) (side-effect-free t))
  `(cl-function
    (lambda
      ,(letf! (defun* allow-other-keys (args)
                (mapcar
                 (lambda (arg)
                   (cond ((nlistp (cdr-safe arg)) arg)
                         ((listp arg) (allow-other-keys arg))
                         (arg)))
                 (if (and (memq '&key args)
                          (not (memq '&allow-other-keys args)))
                     (if (memq '&aux args)
                         (let (newargs arg)
                           (while args
                             (setq arg (pop args))
                             (when (eq arg '&aux)
                               (push '&allow-other-keys newargs))
                             (push arg newargs))
                           (nreverse newargs))
                       (append args (list '&allow-other-keys)))
                   args)))
         (allow-other-keys arglist))
      ,@body)))

;;;###autoload
(defun +default/new-buffer ()
  "TODO"
  (interactive)
  (let ((buffer (generate-new-buffer "*new*")))
    (set-window-buffer nil buffer)
    (with-current-buffer buffer
      (funcall (default-value 'major-mode)))))

;;;###autoload
(defun dotfairy-path (&rest segments)
  "Constructs a file path from SEGMENTS.
Ignores `nil' elements in SEGMENTS."
  (let ((segments (remq nil segments))
        file-name-handler-alist
        dir)
    (while segments
      (setq segment (pop segments)
            dir (expand-file-name
                 (if (listp segment)
                     (apply #'dotfairy-path dir segment)
                   segment)
                 dir)))
    dir))

(defun dotfairy-region-active-p ()
  "Return non-nil if selection is active."
  (declare (side-effect-free t))
  (or (use-region-p)))

;;;###autoload
(defun dotfairy-region-beginning ()
  "Return beginning position of selection."
  (declare (side-effect-free t))
  (region-beginning))

;;;###autoload
(defun dotfairy-region-end ()
  "Return end position of selection."
  (declare (side-effect-free t))
  (region-end))

;;;###autoload
(defun dotfairy-thing-at-point-or-region (&optional thing prompt)
  "Grab the current selection, THING at point, Returns THING if it is a string.
Otherwise, if nothing is found at point and PROMPT is non-nil, prompt for a
string (if PROMPT is a string it'll be used as the prompting string). Returns
nil if all else fails. NOTE: Don't use THING for grabbing symbol-at-point. "
  (declare (side-effect-free t))
  (cond ((stringp thing)
         thing)
        ((dotfairy-region-active-p)
         (buffer-substring-no-properties
          (dotfairy-region-beginning)
          (dotfairy-region-end)))
        ((let ((s (thing-at-point 'symbol)))
           (and (stringp s)
                (if (string-match "\\`[`']?\\(.*?\\)'?\\'" s)
                    (match-string 1 s)
                  s))))
        ((looking-at "(+\\(\\(?:\\sw\\|\\s_\\)+\\)\\_>")
         (match-string-no-properties 1))
        (prompt
         (read-string (if (stringp prompt) prompt "")))
        (t
         "")))

(defmacro cmd! (&rest body)
  "Returns (lambda () (interactive) ,@body)
A factory for quickly producing interaction commands, particularly for keybinds
or aliases."
  (declare (doc-string 1))
  `(lambda (&rest _) (interactive) ,@body))

(defmacro cmd!! (command &optional prefix-arg &rest args)
  "Returns a closure that interactively calls COMMAND with ARGS and PREFIX-ARG.
Like `cmd!', but allows you to change `current-prefix-arg' or pass arguments to
COMMAND. This macro is meant to be used as a target for keybinds (e.g. with
`define-key' or `map!')."
  (declare (doc-string 1) (pure t) (side-effect-free t))
  `(lambda (arg &rest _) (interactive "P")
     (let ((current-prefix-arg (or ,prefix-arg arg)))
       (,(if args
             #'funcall-interactively
           #'call-interactively)
        ,command ,@args))))

(defmacro cmds! (&rest branches)
  "Returns a dispatcher that runs the a command in BRANCHES.
Meant to be used as a target for keybinds (e.g. with `define-key' or `map!').

BRANCHES is a flat list of CONDITION COMMAND pairs. CONDITION is a lisp form
that is evaluated when (and each time) the dispatcher is invoked. If it returns
non-nil, COMMAND is invoked, otherwise it falls through to the next pair.

The last element of BRANCHES can be a COMMANd with no CONDITION. This acts as
the fallback if all other conditions fail.

Otherwise, Emacs will fall through the keybind and search the next keymap for a
keybind (as if this keybind never existed).

See `general-key-dispatch' for what other arguments it accepts in BRANCHES."
  (declare (doc-string 1))
  (let ((docstring (if (stringp (car branches)) (pop branches) ""))
        fallback)
    (when (cl-oddp (length branches))
      (setq fallback (car (last branches))
            branches (butlast branches)))
    (let ((defs (cl-loop for (key value) on branches by 'cddr
                         unless (keywordp key)
                         collect (list key value))))
      `'(menu-item
         ,(or docstring "") nil
         :filter (lambda (&optional _)
                   (let (it)
                     (cond ,@(mapcar (lambda (pred-def)
                                       `((setq it ,(car pred-def))
                                         ,(cadr pred-def)))
                                     defs)
                           (t ,fallback))))))))

(defun dotfairy-rpartial (fn &rest args)
  "Return a partial application of FUN to right-hand ARGS.
ARGS is a list of the last N arguments to pass to FUN. The result is a new
function which does the same as FUN, except that the last N arguments are fixed
at the values with which this function was called."
  (declare (side-effect-free t))
  (lambda (&rest pre-args)
    (apply fn (append pre-args args))))

(defun dotfairy--resolve-path-forms (spec &optional directory)
  "Converts a simple nested series of or/and forms into a series of
`file-exists-p' checks.
For example
  (dotfairy--resolve-path-forms
    '(or A (and B C))
    \"~\")
Returns (approximately):
  '(let* ((_directory \"~\")
          (A (expand-file-name A _directory))
          (B (expand-file-name B _directory))
          (C (expand-file-name C _directory)))
     (or (and (file-exists-p A) A)
         (and (if (file-exists-p B) B)
              (if (file-exists-p C) C))))
This is used by `file-exists-p!' and `project-file-exists-p!'."
  (declare (pure t) (side-effect-free t))
  (if (and (listp spec)
           (memq (car spec) '(or and)))
      (cons (car spec)
            (mapcar (dotfairy-rpartial #'dotfairy--resolve-path-forms directory)
                    (cdr spec)))
    (let ((filevar (make-symbol "file")))
      `(let ((,filevar ,spec))
         (and (stringp ,filevar)
              ,(if directory
                   `(let ((default-directory ,directory))
                      (file-exists-p ,filevar))
                 `(file-exists-p ,filevar))
              ,filevar)))))

;;;###autoload
(defmacro file-exists-p! (files &optional directory)
  "Returns non-nil if the FILES in DIRECTORY all exist.
DIRECTORY is a path; defaults to `default-directory'.
Returns the last file found to meet the rules set by FILES, which can be a
single file or nested compound statement of `and' and `or' statements."
  `(let ((p ,(dotfairy--resolve-path-forms files directory)))
     (and p (expand-file-name p ,directory))))


(defun dotfairy-unquote (exp)
  "Return EXP unquoted."
  (declare (pure t) (side-effect-free t))
  (while (memq (car-safe exp) '(quote function))
    (setq exp (cadr exp)))
  exp)

(defun dotfairy-keyword-name (keyword)
  "Returns the string name of KEYWORD (`keywordp') minus the leading colon."
  (declare (pure t) (side-effect-free t))
  (cl-check-type keyword keyword)
  (substring (symbol-name keyword) 1))

(defun dotfairy--resolve-hook-forms (hooks)
  "Converts a list of modes into a list of hook symbols.
If a mode is quoted, it is left as is. If the entire HOOKS list is quoted, the
list is returned as-is."
  (declare (pure t) (side-effect-free t))
  (let ((hook-list (ensure-list (dotfairy-unquote hooks))))
    (if (eq (car-safe hooks) 'quote)
        hook-list
      (cl-loop for hook in hook-list
               if (eq (car-safe hook) 'quote)
               collect (cadr hook)
               else collect (intern (format "%s-hook" (symbol-name hook)))))))

(defmacro add-transient-hook! (hook-or-function &rest forms)
  "Attaches a self-removing function to HOOK-OR-FUNCTION.

FORMS are evaluated once, when that function/hook is first invoked, then never
again.

HOOK-OR-FUNCTION can be a quoted hook or a sharp-quoted function (which will be
advised)."
  (declare (indent 1))
  (let ((append? (if (eq (car forms) :after) (pop forms)))
        (fn (gensym "dotfairy-transient-hook")))
    `(let ((sym ,hook-or-function))
       (defun ,fn (&rest _)
         ,(format "Transient hook for %S" (dotfairy-unquote hook-or-function))
         ,@forms
         (let ((sym ,hook-or-function))
           (cond ((functionp sym) (advice-remove sym #',fn))
                 ((symbolp sym)   (remove-hook sym #',fn))))
         (unintern ',fn nil))
       (cond ((functionp sym)
              (advice-add ,hook-or-function ,(if append? :after :before) #',fn))
             ((symbolp sym)
              (put ',fn 'permanent-local-hook t)
              (add-hook sym #',fn ,append?))))))

(defmacro add-hook! (hooks &rest rest)
  "A convenience macro for adding N functions to M hooks.

This macro accepts, in order:

  1. The mode(s) or hook(s) to add to. This is either an unquoted mode, an
     unquoted list of modes, a quoted hook variable or a quoted list of hook
     variables.
  2. Optional properties :local, :append, and/or :depth [N], which will make the
     hook buffer-local or append to the list of hooks (respectively),
  3. The function(s) to be added: this can be a quoted function, a quoted list
     thereof, a list of `defun' or `cl-defun' forms, or arbitrary forms (will
     implicitly be wrapped in a lambda).

\(fn HOOKS [:append :local [:depth N]] FUNCTIONS-OR-FORMS...)"
  (declare (indent (lambda (indent-point state)
                     (goto-char indent-point)
                     (when (looking-at-p "\\s-*(")
                       (lisp-indent-defform state indent-point))))
           (debug t))
  (let* ((hook-forms (dotfairy--resolve-hook-forms hooks))
         (func-forms ())
         (defn-forms ())
         append-p local-p remove-p depth)
    (while (keywordp (car rest))
      (pcase (pop rest)
        (:append (setq append-p t))
        (:depth  (setq depth (pop rest)))
        (:local  (setq local-p t))
        (:remove (setq remove-p t))))
    (while rest
      (let* ((next (pop rest))
             (first (car-safe next)))
        (push (cond ((memq first '(function nil))
                     next)
                    ((eq first 'quote)
                     (let ((quoted (cadr next)))
                       (if (atom quoted)
                           next
                         (when (cdr quoted)
                           (setq rest (cons (list first (cdr quoted)) rest)))
                         (list first (car quoted)))))
                    ((memq first '(defun cl-defun))
                     (push next defn-forms)
                     (list 'function (cadr next)))
                    ((prog1 `(lambda (&rest _) ,@(cons next rest))
                       (setq rest nil))))
              func-forms)))
    `(progn
       ,@defn-forms
       (dolist (hook ',(nreverse hook-forms))
         (dolist (func (list ,@func-forms))
           ,(if remove-p
                `(remove-hook hook func ,local-p)
              `(add-hook hook func ,(or depth append-p) ,local-p)))))))

(defmacro remove-hook! (hooks &rest rest)
  "A convenience macro for removing N functions from M hooks.
Takes the same arguments as `add-hook!'.
If N and M = 1, there's no benefit to using this macro over `remove-hook'.
\(fn HOOKS [:append :local] FUNCTIONS)"
  (declare (indent defun) (debug t))
  `(add-hook! ,hooks :remove ,@rest))

;;; Definers
(defmacro defadvice! (symbol arglist &optional docstring &rest body)
  "Define an advice called SYMBOL and add it to PLACES.
ARGLIST is as in `defun'. WHERE is a keyword as passed to `advice-add', and
PLACE is the function to which to add the advice, like in `advice-add'.
DOCSTRING and BODY are as in `defun'.
\(fn SYMBOL ARGLIST &optional DOCSTRING &rest [WHERE PLACES...] BODY\)"
  (declare (doc-string 3) (indent defun))
  (unless (stringp docstring)
    (push docstring body)
    (setq docstring nil))
  (let (where-alist)
    (while (keywordp (car body))
      (push `(cons ,(pop body) (ensure-list ,(pop body)))
            where-alist))
    `(progn
       (defun ,symbol ,arglist ,docstring ,@body)
       (dolist (targets (list ,@(nreverse where-alist)))
         (dolist (target (cdr targets))
           (advice-add target (car targets) #',symbol))))))

(defmacro undefadvice! (symbol _arglist &optional docstring &rest body)
  "Undefine an advice called SYMBOL.
This has the same signature as `defadvice!' an exists as an easy undefiner when
testing advice (when combined with `rotate-text').
\(fn SYMBOL ARGLIST &optional DOCSTRING &rest [WHERE PLACES...] BODY\)"
  (declare (doc-string 3) (indent defun))
  (let (where-alist)
    (unless (stringp docstring)
      (push docstring body))
    (while (keywordp (car body))
      (push `(cons ,(pop body) (ensure-list ,(pop body)))
            where-alist))
    `(dolist (targets (list ,@(nreverse where-alist)))
       (dolist (target (cdr targets))
         (advice-remove target #',symbol)))))

(defvar dotfairy-disabled-packages ()
  "A list of packages that should be ignored by `use-package!' and `after!'.")

(defmacro after! (package &rest body)
  "Evaluate BODY after PACKAGE have loaded.
PACKAGE is a symbol or list of them. These are package names, not modes,
functions or variables. It can be:
- An unquoted package symbol (the name of a package)
    (after! helm BODY...)
- An unquoted list of package symbols (i.e. BODY is evaluated once both magit
  and diff-hl have loaded)
    (after! (magit diff-hl) BODY...)
- An unquoted, nested list of compound package lists, using any combination of
  :or/:any and :and/:all
    (after! (:or package-a package-b ...)  BODY...)
    (after! (:and package-a package-b ...) BODY...)
    (after! (:and package-a (:or package-b package-c) ...) BODY...)
  Without :or/:any/:and/:all, :and/:all are implied.
This is a wrapper around `eval-after-load' that:
1. Suppresses warnings for disabled packages at compile-time
2. No-ops for package that are disabled by the user (via `package!')
3. Supports compound package statements (see below)
4. Prevents eager expansion pulling in autoloaded macros all at once"
  (declare (indent defun) (debug t))
  (if (symbolp package)
      (unless (memq package (bound-and-true-p dotfairy-disabled-packages))
        (list (if (or (not (bound-and-true-p byte-compile-current-file))
                      (require package nil 'noerror))
                  #'progn
                #'with-no-warnings)
              ;; We intentionally avoid `with-eval-after-load' to prevent eager
              ;; macro expansion from pulling (or failing to pull) in autoloaded
              ;; macros/packages.
              `(eval-after-load ',package ',(macroexp-progn body))))
    (let ((p (car package)))
      (cond ((not (keywordp p))
             `(after! (:and ,@package) ,@body))
            ((memq p '(:or :any))
             (macroexp-progn
              (cl-loop for next in (cdr package)
                       collect `(after! ,next ,@body))))
            ((memq p '(:and :all))
             (dolist (next (cdr package))
               (setq body `((after! ,next ,@body))))
             (car body))))))

(defmacro delq! (elt list &optional fetcher)
  "`delq' ELT from LIST in-place.

If FETCHER is a function, ELT is used as the key in LIST (an alist)."
  `(setq ,list (delq ,(if fetcher
                          `(funcall ,fetcher ,elt ,list)
                        elt)
                     ,list)))

(defmacro pushnew! (place &rest values)
  "Push VALUES sequentially into PLACE, if they aren't already present.
This is a variadic `cl-pushnew'."
  (let ((var (make-symbol "result")))
    `(dolist (,var (list ,@values) (with-no-warnings ,place))
       (cl-pushnew ,var ,place :test #'equal))))

(defmacro prependq! (sym &rest lists)
  "Prepend LISTS to SYM in place."
  `(setq ,sym (append ,@lists ,sym)))


;;;###autoload
(defun dotfairy-project-browse (dir)
  "Traverse a file structure starting linearly from DIR."
  (let ((default-directory (file-truename (expand-file-name dir))))
    (call-interactively
     (cond ((bound-and-true-p ivy-mode)
            #'counsel-find-file)
           (#'find-file)))))

;;;###autoload
(defvar dotfairy-real-buffer-functions
  '(dotfairy-dired-buffer-p)
  "A list of predicate functions run to determine if a buffer is real, unlike
`dotfairy-unreal-buffer-functions'. They are passed one argument: the buffer to be
tested.
Should any of its function returns non-nil, the rest of the functions are
ignored and the buffer is considered real.
See `dotfairy-real-buffer-p' for more information.")

;;;###autoload
(defvar dotfairy-unreal-buffer-functions
  '(minibufferp dotfairy-special-buffer-p dotfairy-non-file-visiting-buffer-p)
  "A list of predicate functions run to determine if a buffer is *not* real,
unlike `dotfairy-real-buffer-functions'. They are passed one argument: the buffer to
be tested.
Should any of these functions return non-nil, the rest of the functions are
ignored and the buffer is considered unreal.
See `dotfairy-real-buffer-p' for more information.")

;;;###autoload
(defvar-local dotfairy-real-buffer-p nil
  "If non-nil, this buffer should be considered real no matter what. See
`dotfairy-real-buffer-p' for more information.")

;;;###autoload
(defvar dotfairy-fallback-buffer-name "*scratch*"
  "The name of the buffer to fall back to if no other buffers exist (will create
it if it doesn't exist).")

;;
;;; Functions
;;;###autoload
(defun dotfairy-fallback-buffer ()
  "Returns the fallback buffer, creating it if necessary. By default this is the
scratch buffer. See `dotfairy-fallback-buffer-name' to change this."
  (let (buffer-list-update-hook)
    (get-buffer-create dotfairy-fallback-buffer-name)))

;;;###autoload
(defalias 'dotfairy-buffer-list #'buffer-list)

;;;###autoload
(defun dotfairy-dired-buffer-p (buf)
  "Returns non-nil if BUF is a dired buffer."
  (with-current-buffer buf (derived-mode-p 'dired-mode)))

;;;###autoload
(defun dotfairy-special-buffer-p (buf)
  "Returns non-nil if BUF's name starts and ends with an *."
  (equal (substring (buffer-name buf) 0 1) "*"))

;;;###autoload
(defun dotfairy-temp-buffer-p (buf)
  "Returns non-nil if BUF is temporary."
  (equal (substring (buffer-name buf) 0 1) " "))

;;;###autoload
(defun dotfairy-non-file-visiting-buffer-p (buf)
  "Returns non-nil if BUF does not have a value for `buffer-file-name'."
  (not (buffer-file-name buf)))

;;;###autoload
(defun dotfairy-real-buffer-p (buffer-or-name)
  "Returns t if BUFFER-OR-NAME is a 'real' buffer.
A real buffer is a useful buffer; a first class citizen in Dotfairy. Real ones
should get special treatment, because we will be spending most of our time in
them. Unreal ones should be low-profile and easy to cast aside, so we can focus
on real ones.
The exact criteria for a real buffer is:
  1. A non-nil value for the buffer-local value of the `dotfairy-real-buffer-p'
     variable OR
  2. Any function in `dotfairy-real-buffer-functions' returns non-nil OR
  3. None of the functions in `dotfairy-unreal-buffer-functions' must return
     non-nil.
If BUFFER-OR-NAME is omitted or nil, the current buffer is tested."
  (or (bufferp buffer-or-name)
      (stringp buffer-or-name)
      (signal 'wrong-type-argument (list '(bufferp stringp) buffer-or-name)))
  (when-let (buf (get-buffer buffer-or-name))
    (when-let (basebuf (buffer-base-buffer buf))
      (setq buf basebuf))
    (and (buffer-live-p buf)
         (not (dotfairy-temp-buffer-p buf))
         (or (buffer-local-value 'dotfairy-real-buffer-p buf)
             (run-hook-with-args-until-success 'dotfairy-real-buffer-functions buf)
             (not (run-hook-with-args-until-success 'dotfairy-unreal-buffer-functions buf))))))

;;;###autoload
(defun dotfairy-unreal-buffer-p (buffer-or-name)
  "Return t if BUFFER-OR-NAME is an 'unreal' buffer.
See `dotfairy-real-buffer-p' for details on what that means."
  (not (dotfairy-real-buffer-p buffer-or-name)))

;;;###autoload
(defun dotfairy-buffers-in-mode (modes &optional buffer-list derived-p)
  "Return a list of buffers whose `major-mode' is `eq' to MODE(S).
If DERIVED-P, test with `derived-mode-p', otherwise use `eq'."
  (let ((modes (ensure-list modes)))
    (cl-remove-if-not (if derived-p
                          (lambda (buf)
                            (with-current-buffer buf
                              (apply #'derived-mode-p modes)))
                        (lambda (buf)
                          (memq (buffer-local-value 'major-mode buf) modes)))
                      (or buffer-list (dotfairy-buffer-list)))))

;;;###autoload
(defun dotfairy-buried-buffers (&optional buffer-list)
  "Get a list of buffers that are buried."
  (cl-remove-if #'get-buffer-window (or buffer-list (dotfairy-buffer-list))))

;;;###autoload
(defun dotfairy-matching-buffers (pattern &optional buffer-list)
  "Get a list of all buffers that match the regex PATTERN."
  (cl-loop for buf in (or buffer-list (dotfairy-buffer-list))
           when (string-match-p pattern (buffer-name buf))
           collect buf))

;;;###autoload
(defun dotfairy-kill-buffer-and-windows (buffer)
  "Kill the buffer and delete all the windows it's displayed in."
  (dolist (window (get-buffer-window-list buffer))
    (unless (one-window-p t)
      (delete-window window)))
  (kill-buffer buffer))

;;;###autoload
(defun dotfairy-fixup-windows (windows)
  "Ensure that each of WINDOWS is showing a real buffer or the fallback buffer."
  (dolist (window windows)
    (with-selected-window window
      (when (dotfairy-unreal-buffer-p (window-buffer))
        (previous-buffer)
        (when (dotfairy-unreal-buffer-p (window-buffer))
          (switch-to-buffer (dotfairy-fallback-buffer)))))))

;;;###autoload
(defun dotfairy-kill-buffer-fixup-windows (buffer)
  "Kill the BUFFER and ensure all the windows it was displayed in have switched
to a real buffer or the fallback buffer."
  (let ((windows (get-buffer-window-list buffer)))
    (kill-buffer buffer)
    (dotfairy-fixup-windows (cl-remove-if-not #'window-live-p windows))))

;;;###autoload
(defun dotfairy-kill-matching-buffers (pattern &optional buffer-list)
  "Kill all buffers (in current workspace OR in BUFFER-LIST) that match the
regex PATTERN. Returns the number of killed buffers."
  (let ((buffers (dotfairy-matching-buffers pattern buffer-list)))
    (dolist (buf buffers (length buffers))
      (kill-buffer buf))))


(defun dotfairy-exec-process (command &rest args)
  "Execute COMMAND with ARGS synchronously.Unlike `ss-process',
this pipes output to `standard-output' on the fly to
simulate 'exec' in the shell,
so batch scripts could run external programs
synchronously without sacrificing their output.
Warning: freezes indefinitely on any stdin prompt."
  ;; FIXME Is there any way to handle prompts?
  ;; (ssh-manager--info (mapconcat 'identity args " "))
  (with-temp-buffer
    (cons (let ((process
                 (make-process :name command
                               :buffer (current-buffer)
                               :command (cons command (remq nil args))
                               :connection-type 'pipe))
                done-p)
            (set-process-filter
             process (lambda (_process output)
                       (princ output (current-buffer))
                       (princ output)))
            (set-process-sentinel
             process (lambda (process _event)
                       (when (memq (process-status process) '(exit stop))
                         (setq done-p t))))
            (while (not done-p)
              (sit-for 0.1))
            (process-exit-status process))
          (string-trim (buffer-string)))))

;;;###autoload
(defun dotfairy-call-process (command &rest args)
  "Execute COMMAND with ARGS synchronously.
Returns (STATUS . OUTPUT) when it is done, where STATUS is the returned error
code of the process and OUTPUT is its stdout output."
  (with-temp-buffer
    (cons (or (apply #'call-process command nil t nil (remq nil args))
              -1)
          (string-trim (buffer-string)))))

(defun childframe-workable-p ()
  "Whether childframe is workable."
  (not (or noninteractive
           emacs-basic-display
           (not (display-graphic-p)))))

(defun childframe-completion-workable-p ()
  "Whether childframe completion is workable."
  (and (eq dotfairy-completion-style 'childframe)
       (childframe-workable-p)))

;; Browse URL
(defun dotfairy-webkit-browse-url (url &optional pop-buffer new-session)
  "Browse URL with xwidget-webkit' and switch or pop to the buffer.

   POP-BUFFER specifies whether to pop to the buffer.
   NEW-SESSION specifies whether to create a new xwidget-webkit session.
  Interactively, URL defaults to the string looking like a url around point."
  (interactive (progn
                 (require 'browse-url)
                 (browse-url-interactive-arg "URL: ")))
  (xwidget-webkit-browse-url url new-session)
  (let ((buf (xwidget-buffer (and (fboundp 'xwidget-webkit-current-session)
                                  (xwidget-webkit-current-session)))))
    (when (buffer-live-p buf)
      (and (eq buf (current-buffer)) (quit-window))
      (if pop-buffer
          (pop-to-buffer buf)
        (switch-to-buffer buf)))))

(defun too-long-file-p ()
  "Check whether the file is too long."
  (or (> (buffer-size) 500000)
      (and (fboundp 'buffer-line-statistics)
           (> (car (buffer-line-statistics)) 10000))))


(defun remember-init ()
  "Remember current position and setup."
  (interactive)
  (point-to-register 8)
  (message "Have remember one position"))

(defun remember-jump ()
  "Jump to latest position and setup."
  (interactive)
  (let ((tmp (point-marker)))
    (jump-to-register 8)
    (set-register 8 tmp))
  (message "Have back to remember position"))

(defun open-newline-above (arg)
  "Move to the previous line (like vi) and then opens a line."
  (interactive "p")
  (beginning-of-line)
  (open-line arg)
  (if (not (member major-mode '(haskell-mode org-mode literate-haskell-mode)))
      (indent-according-to-mode)
    (beginning-of-line)))

(defun open-newline-below (arg)
  "Move to the next line (like vi) and then opens a line."
  (interactive "p")
  (end-of-line)
  (open-line arg)
  (call-interactively 'next-line arg)
  (if (not (member major-mode '(haskell-mode org-mode literate-haskell-mode)))
      (indent-according-to-mode)
    (beginning-of-line)))

(defun duplicate-line-or-region-above (&optional reverse)
  "Duplicate current line or region above.
By default, duplicate current line above.
If mark is activate, duplicate region lines above.
Default duplicate above, unless option REVERSE is non-nil."
  (interactive)
  (let ((original-column (current-column))
        duplicate-content)
    (if mark-active
        ;; If mark active.
        (let ((region-start-pos (region-beginning))
              (region-end-pos (region-end)))
          ;; Set duplicate start line position.
          (setq region-start-pos (progn
                                   (goto-char region-start-pos)
                                   (line-beginning-position)))
          ;; Set duplicate end line position.
          (setq region-end-pos (progn
                                 (goto-char region-end-pos)
                                 (line-end-position)))
          ;; Get duplicate content.
          (setq duplicate-content (buffer-substring region-start-pos region-end-pos))
          (if reverse
              ;; Go to next line after duplicate end position.
              (progn
                (goto-char region-end-pos)
                (forward-line +1))
            ;; Otherwise go to duplicate start position.
            (goto-char region-start-pos)))
      ;; Otherwise set duplicate content equal current line.
      (setq duplicate-content (buffer-substring
                               (line-beginning-position)
                               (line-end-position)))
      ;; Just move next line when `reverse' is non-nil.
      (and reverse (forward-line 1))
      ;; Move to beginning of line.
      (beginning-of-line))
    ;; Open one line.
    (open-line 1)
    ;; Insert duplicate content and revert column.
    (insert duplicate-content)
    (move-to-column original-column t)))

(defun duplicate-line-or-region-below ()
  "Duplicate current line or region below.
By default, duplicate current line below.
If mark is activate, duplicate region lines below."
  (interactive)
  (duplicate-line-or-region-above t))

(defun duplicate-line-above-comment (&optional reverse)
  "Duplicate current line above, and comment current line."
  (interactive)
  (if reverse
      (duplicate-line-or-region-below)
    (duplicate-line-or-region-above))
  (save-excursion
    (if reverse
        (forward-line -1)
      (forward-line +1))
    (comment-or-uncomment-region+)))

(defun duplicate-line-below-comment ()
  "Duplicate current line below, and comment current line."
  (interactive)
  (duplicate-line-above-comment t))

(defun comment-or-uncomment-region+ ()
  "This function is to comment or uncomment a line or a region."
  (interactive)
  (let (beg end)
    (if mark-active
        (progn
          (setq beg (region-beginning))
          (setq end (region-end)))
      (setq beg (line-beginning-position))
      (setq end (line-end-position)))
    (save-excursion
      (comment-or-uncomment-region beg end))))

(defvar dotfairy-inhibit-log (not (or noninteractive init-file-debug))
  "If non-nil, suppress `dotfairy-log' output.")

(defun dotfairy--log (text &rest args)
  (let ((inhibit-message (not init-file-debug)))
    (apply #'message
           (concat "* " (format-time-string "%H:%M:%S") ": " text)
           args)))

(defmacro dotfairy-log (message &rest args)
  "Log a message in *Messages*.

Does not emit the message in the echo area. This is a macro instead of a
function to prevent the potentially expensive evaluation of its arguments when
debug mode is off. Return non-nil."
  (declare (debug t))
  `(unless dotfairy-inhibit-log (dotfairy--log ,message ,@args)))

(defun set-from-minibuffer (sym)
  "Set SYM value from minibuffer."
  (eval-expression
   (minibuffer-with-setup-hook
       (lambda ()
         (add-function :before-until (local 'eldoc-documentation-function)
           #'elisp-eldoc-documentation-function)
         (run-hooks 'eval-expression-minibuffer-setup-hook)
         (goto-char (minibuffer-prompt-end))
         (forward-char (length (format "(setq %S " sym))))
     (read-from-minibuffer
      "Eval: "
      (let ((sym-value (symbol-value sym)))
        (format
         (if (or (consp sym-value)
                 (and (symbolp sym-value)
                      (not (null sym-value))
                      (not (keywordp sym-value))))
             "(setq %s '%S)"
           "(setq %s %S)")
         sym sym-value))
      read-expression-map t
      'read-expression-history))))

;;;###autoload
(defun dotfairy-pcre-quote (str)
  "Like `reqexp-quote', but for PCREs."
  (let ((special '(?. ?^ ?$ ?* ?+ ?? ?{ ?\\ ?\[ ?\| ?\())
        (quoted nil))
    (mapc (lambda (c)
            (when (memq c special)
              (push ?\\ quoted))
            (push c quoted))
          str)
    (concat (nreverse quoted))))

;; Browse URL
(defun dotfairy-browse-url (url)
  "Open URL using a configurable method.
See `browse-url' for more details."
  (interactive (progn
                 (require 'browse-url)
                 (browse-url-interactive-arg "URL: ")))
  (if (and (featurep 'xwidget-internal) (display-graphic-p))
      (dotfairy-webkit-browse-url url t)
    (browse-url url)))

(defun create-scratch-buffer ()
  "Create a scratch buffer."
  (interactive)
  (switch-to-buffer (get-buffer-create "*scratch*"))
  (lisp-interaction-mode))

(defun save-buffer-as-utf8 (coding-system)
  "Revert a buffer with `CODING-SYSTEM' and save as UTF-8."
  (interactive "zCoding system for visited file (default nil):")
  (revert-buffer-with-coding-system coding-system)
  (set-buffer-file-coding-system 'utf-8)
  (save-buffer))

(defun save-buffer-gbk-as-utf8 ()
  "Revert a buffer with GBK and save as UTF-8."
  (interactive)
  (save-buffer-as-utf8 'gbk))

(defun selected-region-or-symbol-at-point ()
  "Return the selected region, otherwise return the symbol at point."
  (if (region-active-p)
      (buffer-substring-no-properties (region-beginning) (region-end))
    (thing-at-point 'symbol t)))

(provide 'init-funcs)
;;; init-funcs.el ends here
