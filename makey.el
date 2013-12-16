;;; makey.el --- interactive commandline mode

;; Copyright (C) 2010-2013  The Makey Project Developers.
;; Copyright (C) 2013 Mickey Petersen

;; Author: Mickey Petersen <mickey@masteringemacs.org>
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
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(eval-when-compile (require 'cl-lib))

(defvar makey-key-mode-keymaps)
(defvar makey-key-mode-last-buffer)
(defvar makey-pre-key-mode-window-conf)

;;; Options

(defcustom makey-key-mode-show-usage t
  "Whether to show usage information when entering a popup."
  :group 'makey
  :type 'boolean)

;;; Faces

(defface makey-key-mode-header-face
  '((t :inherit font-lock-keyword-face))
  "Face for key mode header lines."
  :group 'makey-faces)

(defface makey-key-mode-button-face
  '((t :inherit font-lock-builtin-face))
  "Face for key mode buttons."
  :group 'makey-faces)

(defface makey-key-mode-switch-face
  '((t :inherit font-lock-warning-face))
  "Face for key mode switches."
  :group 'makey-faces)

(defface makey-key-mode-args-face
  '((t :inherit widget-field))
  "Face for key mode switch arguments."
  :group 'makey-faces)

;;; Keygroups
;;;###autoload
(defvar makey-key-mode-groups
  '((dispatch
     (actions
      ("b" "Branching"       makey-key-mode-popup-branching)
      ("B" "Bisecting"       makey-key-mode-popup-bisecting)
      ("c" "Committing"      makey-key-mode-popup-committing)
      ("d" "Diff worktree"   makey-diff-working-tree)
      ("D" "Diff"            makey-diff)
      ("f" "Fetching"        makey-key-mode-popup-fetching)
      ("F" "Pulling"         makey-key-mode-popup-pulling)
      ("g" "Refresh Buffers" makey-refresh-all)
      ("l" "Logging"         makey-key-mode-popup-logging)
      ("m" "Merging"         makey-key-mode-popup-merging)
      ("M" "Remoting"        makey-key-mode-popup-remoting)
      ("P" "Pushing"         makey-key-mode-popup-pushing)
      ("o" "Submoduling"     makey-key-mode-popup-submodule)
      ("r" "Rewriting"       makey-key-mode-popup-rewriting)
      ("s" "Show Status"     makey-status)
      ("S" "Stage all"       makey-stage-all)
      ("t" "Tagging"         makey-key-mode-popup-tagging)
      ("U" "Unstage all"     makey-unstage-all)
      ("v" "Show Commit"     makey-show-commit)
      ("V" "Show File"       makey-show)
      ("w" "Wazzup"          makey-wazzup)
      ("X" "Reset worktree"  makey-reset-working-tree)
      ("y" "Cherry"          makey-cherry)
      ("z" "Stashing"        makey-key-mode-popup-stashing)
      ("!" "Running"         makey-key-mode-popup-running)
      ("$" "Show Process"    makey-display-process)))

    (logging
     (man-page "git-log")
     (actions
      ("l" "Short" makey-log)
      ("L" "Long" makey-log-long)
      ("h" "Head Reflog" makey-reflog-head)
      ("f" "File log" makey-file-log)
      ("rl" "Ranged short" makey-log-ranged)
      ("rL" "Ranged long" makey-log-long-ranged)
      ("rh" "Reflog" makey-reflog))
     (switches
      ("-m" "Only merge commits" "--merges")
      ("-do" "Date Order" "--date-order")
      ("-f" "First parent" "--first-parent")
      ("-i" "Case insensitive patterns" "-i")
      ("-pr" "Pickaxe regex" "--pickaxe-regex")
      ("-g" "Show Graph" "--graph")
      ("-n" "Name only" "--name-only")
      ("-am" "All match" "--all-match")
      ("-al" "All" "--all"))
     (arguments
      ("=r" "Relative" "--relative=" read-directory-name)
      ("=c" "Committer" "--committer=" read-from-minibuffer)
      ("=>" "Since" "--since=" read-from-minibuffer)
      ("=<" "Before" "--before=" read-from-minibuffer)
      ("=a" "Author" "--author=" read-from-minibuffer)
      ("=g" "Grep messages" "--grep=" read-from-minibuffer)
      ("=G" "Grep patches" "-G" read-from-minibuffer)
      ("=L" "Trace evolution of line range [long log only]"
       "-L" makey-read-file-trace)
      ("=s" "Pickaxe search" "-S" read-from-minibuffer)
      ("=b" "Branches" "--branches=" read-from-minibuffer)
      ("=R" "Remotes" "--remotes=" read-from-minibuffer)))

    (running
     (actions
      ("!" "Command from root" makey-shell-command)
      (":" "Git command" makey-git-command)
      ("g" "git gui" makey-run-git-gui)
      ("k" "gitk" makey-run-gitk)))

    (fetching
     (man-page "git-fetch")
     (actions
      ("f" "Current" makey-fetch-current)
      ("a" "All" makey-remote-update)
      ("o" "Other" makey-fetch))
     (switches
      ("-p" "Prune" "--prune")))

    (pushing
     (man-page "git-push")
     (actions
      ("P" "Push" makey-push)
      ("t" "Push tags" makey-push-tags))
     (switches
      ("-f" "Force" "--force")
      ("-d" "Dry run" "-n")
      ("-u" "Set upstream" "-u")))

    (pulling
     (man-page "git-pull")
     (actions
      ("F" "Pull" makey-pull))
     (switches
      ("-f" "Force" "--force")
      ("-r" "Rebase" "--rebase")))

    (branching
     (man-page "git-branch")
     (actions
      ("v" "Branch manager" makey-branch-manager)
      ("b" "Checkout" makey-checkout)
      ("c" "Create" makey-create-branch)
      ("r" "Rename" makey-rename-branch)
      ("k" "Delete" makey-delete-branch))
     (switches
      ("-t" "Set upstream configuration" "--track")
      ("-m" "Merged to HEAD" "--merged")
      ("-M" "Merged to master" "--merged=master")
      ("-n" "Not merged to HEAD" "--no-merged")
      ("-N" "Not merged to master" "--no-merged=master"))
     (arguments
      ("=c" "Contains" "--contains=" makey-read-rev-with-default)
      ("=m" "Merged" "--merged=" makey-read-rev-with-default)
      ("=n" "Not merged" "--no-merged=" makey-read-rev-with-default)))

    (remoting
     (man-page "git-remote")
     (actions
      ("v" "Remote manager" makey-branch-manager)
      ("a" "Add" makey-add-remote)
      ("r" "Rename" makey-rename-remote)
      ("k" "Remove" makey-remove-remote)))

    (tagging
     (man-page "git-tag")
     (actions
      ("t" "Create" makey-tag)
      ("k" "Delete" makey-delete-tag))
     (switches
      ("-a" "Annotate" "--annotate")
      ("-f" "Force" "--force")
      ("-s" "Sign" "--sign")))

    (stashing
     (man-page "git-stash")
     (actions
      ("z" "Save" makey-stash)
      ("s" "Snapshot" makey-stash-snapshot))
     (switches
      ("-k" "Keep index" "--keep-index")
      ("-u" "Include untracked files" "--include-untracked")
      ("-a" "Include all files" "--all")))

    (committing
     (man-page "git-commit")
     (actions
      ("c" "Commit" makey-commit)
      ("a" "Amend"  makey-commit-amend)
      ("e" "Extend" makey-commit-extend)
      ("r" "Reword" makey-commit-reword)
      ("f" "Fixup"  makey-commit-fixup)
      ("s" "Squash" makey-commit-squash))
     (switches
      ("-r" "Replace the tip of current branch" "--amend")
      ("-R" "Claim authorship and reset author date" "--reset-author")
      ("-a" "Stage all modified and deleted files" "--all")
      ("-e" "Allow empty commit" "--allow-empty")
      ("-v" "Show diff of changes to be committed" "--verbose")
      ("-n" "Bypass git hooks" "--no-verify")
      ("-s" "Add Signed-off-by line" "--signoff")
      ("-S" "Sign using gpg" "--gpg-sign")))

    (merging
     (man-page "git-merge")
     (actions
      ("m" "Merge" makey-merge)
      ("A" "Abort" makey-merge-abort))
     (switches
      ("-ff" "Fast-forward only" "--ff-only")
      ("-nf" "No fast-forward" "--no-ff")
      ("-sq" "Squash" "--squash"))
     (arguments
      ("-st" "Strategy" "--strategy=" read-from-minibuffer)))

    (rewriting
     (actions
      ("b" "Begin" makey-rewrite-start)
      ("s" "Stop" makey-rewrite-stop)
      ("a" "Abort" makey-rewrite-abort)
      ("f" "Finish" makey-rewrite-finish)
      ("*" "Set unused" makey-rewrite-set-unused)
      ("." "Set used" makey-rewrite-set-used)))

    (apply-mailbox
     (man-page "git-am")
     (actions
      ("J" "Apply Mailbox" makey-apply-mailbox))
     (switches
      ("-s" "add a Signed-off-by line to the commit message" "--signoff")
      ("-3" "allow fall back on 3way merging if needed" "--3way")
      ("-k" "pass -k flag to git-mailinfo" "--keep")
      ("-c" "strip everything before a scissors line" "--scissors")
      ("-p" "pass it through git-apply" "-p")
      ("-r" "override error message when patch failure occurs" "--resolvemsg")
      ("-d" "lie about committer date" "--committer-date-is-author-date")
      ("-D" "use current timestamp for author date" "--ignore-date")
      ("-b" "pass -b flag to git-mailinfo" "--keep-non-patch"))
     (arguments
      ("=p" "format the patch(es) are in" "--patch-format")))

    (submodule
     (man-page "git-submodule")
     (actions
      ("u" "Update" makey-submodule-update)
      ("b" "Both update and init" makey-submodule-update-init)
      ("i" "Init" makey-submodule-init)
      ("s" "Sync" makey-submodule-sync)))

    (bisecting
     (man-page "git-bisect")
     (actions
      ("b" "Bad" makey-bisect-bad)
      ("g" "Good" makey-bisect-good)
      ("k" "Skip" makey-bisect-skip)
      ("r" "Reset" makey-bisect-reset)
      ("s" "Start" makey-bisect-start)
      ("u" "Run" makey-bisect-run)))

    (diff-options
     (actions
      ("s" "Set" makey-set-diff-options)
      ("d" "Set default" makey-set-default-diff-options)
      ("c" "Save default" makey-save-default-diff-options)
      ("r" "Reset to default" makey-reset-diff-options)
      ("h" "Toggle Hunk Refinement" makey-toggle-diff-refine-hunk))
     (switches
      ("-m" "Show smallest possible diff" "--minimal")
      ("-p" "Use patience diff algorithm" "--patience")
      ("-h" "Use histogram diff algorithm" "--histogram")
      ("-b" "Ignore whitespace changes" "--ignore-space-change")
      ("-w" "Ignore all whitespace" "--ignore-all-space")
      ("-W" "Show surrounding functions" "--function-context"))
     ))
  "Holds the key, help, function mapping for the log-mode.
If you modify this make sure you reset `makey-key-mode-keymaps'
to nil.")

(defun makey-key-mode-delete-group (group master-group)
  "Delete a group from MASTER-GROUP"
  (let ((items (assoc group master-group)))
    (when items
      ;; reset the cache
      (setq makey-key-mode-keymaps nil)
      ;; delete the whole group
      (setq master-group
            (delq items master-group))
      ;; unbind the defun
      (makey-key-mode-de-generate group))
    master-group))

(defun makey-key-mode-add-group (group master-group)
  "Add a new group to MASTER-GROUP
If there already is a group of that name then this will
completely remove it and put in its place an empty one of the
same name."
  (when (assoc group master-group)
    (makey-key-mode-delete-group group master-group))
  (setq master-group
        (cons (list group (list 'actions) (list 'switches))
              master-group)))

(defun makey-key-mode-key-defined-p (for-group key)
  "Return t if KEY is defined as any option within FOR-GROUP
The option may be a switch, argument or action."
  (catch 'result
    (let ((options (makey-key-mode-options-for-group for-group)))
      (dolist (type '(actions switches arguments))
        (when (assoc key (assoc type options))
          (throw 'result t))))))

(defun makey-key-mode-update-group (for-group thing &rest args)
  "Abstraction for setting values in `makey-key-mode-keymaps'."
  (let* ((options (makey-key-mode-options-for-group for-group))
         (things (assoc thing options))
         (key (car args)))
    (if (cdr things)
        (if (makey-key-mode-key-defined-p for-group key)
            (error "%s is already defined in the %s group." key for-group)
          (setcdr (cdr things) (cons args (cddr things))))
      (setcdr things (list args)))
    (setq makey-key-mode-keymaps nil)
    things))

(defun makey-key-mode-insert-argument (for-group key desc arg read-func)
  "Add a new binding KEY in FOR-GROUP which will use READ-FUNC
to receive input to apply to argument ARG git is run.  DESC should
be a brief description of the binding."
  (makey-key-mode-update-group for-group 'arguments key desc arg read-func))

(defun makey-key-mode-insert-switch (for-group key desc switch)
  "Add a new binding KEY in FOR-GROUP which will add SWITCH to git's
command line when it runs.  DESC should be a brief description of
the binding."
  (makey-key-mode-update-group for-group 'switches key desc switch))

(defun makey-key-mode-insert-action (for-group key desc func)
  "Add a new binding KEY in FOR-GROUP which will run command FUNC.
DESC should be a brief description of the binding."
  (makey-key-mode-update-group for-group 'actions key desc func))

(defun makey-key-mode-options-for-group (for-group)
  "Retrieve the options for the group FOR-GROUP.
This includes switches, commands and arguments."
  (funcall (intern (concat "makey-key-mode-options-for-" (symbol-name for-group)))))

(defun makey-key-mode-help (for-group)
  "Provide help for a key within FOR-GROUP
The user is prompted for the key."
  (let* ((opts (makey-key-mode-options-for-group for-group))
         (man-page (cadr (assoc 'man-page opts)))
         (seq (read-key-sequence
               (format "Enter command prefix%s: "
                       (if man-page
                           (format ", `?' for man `%s'" man-page)
                         ""))))
         (actions (cdr (assoc 'actions opts))))
    (cond
     ;; if it is an action popup the help for the to-be-run function
     ((assoc seq actions) (describe-function (nth 2 (assoc seq actions))))
     ;; if there is "?" show a man page if there is one
     ((equal seq "?")
      (if man-page
          (man man-page)
        (error "No man page associated with `%s'" for-group)))
     (t (error "No help associated with `%s'" seq)))))

(defun makey-key-mode-exec-at-point ()
  "Run action/args/option at point."
  (interactive)
  (let ((key (or (get-text-property (point) 'key-group-executor)
                 (error "Nothing at point to do."))))
    (call-interactively (lookup-key (current-local-map) key))))

(defun makey-key-mode-jump-to-next-exec ()
  "Jump to the next action/args/option point."
  (interactive)
  (let* ((oldp (point))
         (old  (get-text-property oldp 'key-group-executor))
         (p    (if (= oldp (point-max)) (point-min) (1+ oldp))))
    (while (let ((new (get-text-property p 'key-group-executor)))
             (and (not (= p oldp)) (or (not new) (eq new old))))
      (setq p (if (= p (point-max)) (point-min) (1+ p))))
    (goto-char p)
    (skip-chars-forward " ")))

;;; Keymaps

(defvar makey-key-mode-keymaps nil
  "This will be filled lazily with proper keymaps.
These keymaps are created using `define-key' as they're requested.")

(defun makey-key-mode-build-keymap (for-group)
  "Construct a normal looking keymap for the key mode to use.
Put it in `makey-key-mode-keymaps' for fast lookup."
  (let* ((options (makey-key-mode-options-for-group for-group))
         (actions (cdr (assoc 'actions options)))
         (switches (cdr (assoc 'switches options)))
         (arguments (cdr (assoc 'arguments options)))
         (lisp-variables (cdr (assoc 'lisp-variables options)))
         (map (make-sparse-keymap)))
    (suppress-keymap map 'nodigits)
    ;; ret dwim
    (define-key map (kbd "RET") 'makey-key-mode-exec-at-point)
    ;; tab jumps to the next "button"
    (define-key map (kbd "TAB") 'makey-key-mode-jump-to-next-exec)

    ;; all maps should `quit' with `C-g' or `q'
    (define-key map (kbd "C-g") `(lambda ()
                                   (interactive)
                                   (makey-key-mode-command nil)))
    (define-key map (kbd "q")   `(lambda ()
                                   (interactive)
                                   (makey-key-mode-command nil)))
    ;; run help
    (define-key map (kbd "?") `(lambda ()
                                 (interactive)
                                 (makey-key-mode-help ',for-group)))

    (let ((defkey (lambda (k action)
                    ;; (when (and (lookup-key map (car k))
                    ;;            (not (numberp (lookup-key map (car k)))))
                    ;;   (message "Warning: overriding binding for `%s' in %S"
                    ;;            (car k) for-group)
                    ;;   (ding)
                    ;;   (sit-for 2))
                    (define-key map (kbd (car k))
                      `(lambda () (interactive) ,action)))))
      (dolist (k actions)
        (funcall defkey k `(makey-key-mode-command ',(nth 2 k))))
      (dolist (k switches)
        (funcall defkey k `(makey-key-mode-toggle-option ',for-group ,(nth 2 k))))
      (dolist (k lisp-variables)
        (funcall defkey k `(makey-key-mode-add-lisp-variable
                            ',for-group ,(nth 2 k) ',(nth 3 k))))
      (dolist (k arguments)
        (funcall defkey k `(makey-key-mode-add-argument
                            ',for-group ,(nth 2 k) ',(nth 3 k)))))

    (push (cons for-group map) makey-key-mode-keymaps)
    map))

;;; Toggling and Running

(defvar makey-key-mode-prefix nil
  "Prefix argument to the command that brought up the key-mode window.
For internal use.  Used by the command that's eventually invoked.")

(defvar makey-key-mode-current-args nil
  "A hash-table of current argument set.
These will eventually make it to the git command-line.")

(defvar makey-key-mode-current-variables nil
  "A hash-table of current lisp variables set.
These will get let-bound when an action is called")

(defvar makey-key-mode-current-options nil
  "Current option set.
These will eventually make it to the git command-line.")

(defvar makey-custom-options nil
  "List of custom options to pass to Git.
Do not customize this (used in the `makey-key-mode' implementation).")

(defun makey-key-mode-command (func)
  (let ((current-prefix-arg (or current-prefix-arg makey-key-mode-prefix))
        (makey-custom-options makey-key-mode-current-options))
    (maphash (lambda (k v)
               (push (concat k v) makey-custom-options))
             makey-key-mode-current-args)
    (let ((local-let-cells '()))
      (maphash (lambda (k v)
                 (add-to-list 'local-let-cells
                              (list (intern k) v)))
               makey-key-mode-current-variables)
      (eval `(let* ,local-let-cells
               (when func
                 (call-interactively func)))))
    (set-window-configuration makey-pre-key-mode-window-conf)
    (kill-buffer makey-key-mode-last-buffer)))


(defun makey-key-mode-add-lisp-variable (for-group lisp-variable-name input-func)
  (let ((input (funcall input-func (concat lisp-variable-name ": "))))
    (puthash lisp-variable-name input makey-key-mode-current-variables)
    (makey-key-mode-redraw for-group)))

(defun makey-key-mode-add-argument (for-group arg-name input-func)
  (let ((input (funcall input-func (concat arg-name ": "))))
    (puthash arg-name input makey-key-mode-current-args)
    (makey-key-mode-redraw for-group)))

(defun makey-key-mode-toggle-option (for-group option-name)
  "Toggles the appearance of OPTION-NAME in `makey-key-mode-current-options'."
  (if (member option-name makey-key-mode-current-options)
      (setq makey-key-mode-current-options
            (delete option-name makey-key-mode-current-options))
    (add-to-list 'makey-key-mode-current-options option-name))
  (makey-key-mode-redraw for-group))

;;; Mode

(defvar makey-key-mode-buf-name "*makey-key: %s*"
  "Format string to create the name of the makey-key buffer.")

(defvar makey-key-mode-last-buffer nil
  "Store the last makey-key buffer used.")

(defvar makey-pre-key-mode-window-conf nil
  "Will hold the pre-menu configuration of makey.")

(defun makey-key-mode (for-group &optional original-opts)
  "Mode for makey key selection.
All commands, switches and options can be toggled/actioned with
the key combination highlighted before the description."
  (interactive)
  ;; save the window config to restore it as was (no need to make this
  ;; buffer local)
  (setq makey-pre-key-mode-window-conf
        (current-window-configuration))
  ;; setup the mode, draw the buffer
  (let ((buf (get-buffer-create (format makey-key-mode-buf-name
                                        (symbol-name for-group)))))
    (setq makey-key-mode-last-buffer buf)
    (split-window-vertically)
    (other-window 1)
    (switch-to-buffer buf)
    (kill-all-local-variables)
    (set (make-local-variable 'scroll-margin) 0)
    (set (make-local-variable
          'makey-key-mode-current-options)
         original-opts)
    (set (make-local-variable
          'makey-key-mode-current-args)
         (make-hash-table))
    (set (make-local-variable
          'makey-key-mode-current-variables)
         (make-hash-table))
    (set (make-local-variable 'makey-key-mode-prefix) current-prefix-arg)
    (makey-key-mode-redraw for-group))
  (when makey-key-mode-show-usage
    (message (concat "Type a prefix key to toggle it. "
                     "Run 'actions' with their prefixes. "
                     "'?' for more help."))))

(defun makey-key-mode-get-key-map (for-group)
  "Get or build the keymap for FOR-GROUP."
  (or (cdr (assoc for-group makey-key-mode-keymaps))
      (makey-key-mode-build-keymap for-group)))

(defun makey-key-mode-redraw (for-group)
  "(re)draw the makey key buffer."
  (let ((buffer-read-only nil)
        (current-exec (get-text-property (point) 'key-group-executor))
        (new-exec-pos)
        (old-point (point))
        (is-first (zerop (buffer-size)))
        (actions-p nil))
    (erase-buffer)
    (make-local-variable 'font-lock-defaults)
    (use-local-map (makey-key-mode-get-key-map for-group))
    (setq actions-p (makey-key-mode-draw for-group))
    (delete-trailing-whitespace)
    (setq mode-name "makey-key-mode" major-mode 'makey-key-mode)
    (when current-exec
      (setq new-exec-pos
            (cdr (assoc current-exec
                        (makey-key-mode-build-exec-point-alist)))))
    (cond ((and is-first actions-p)
           (goto-char actions-p)
           (makey-key-mode-jump-to-next-exec))
          (new-exec-pos
           (goto-char new-exec-pos)
           (skip-chars-forward " "))
          (t
           (goto-char old-point))))
  (setq buffer-read-only t)
  (fit-window-to-buffer))

(defun makey-key-mode-build-exec-point-alist ()
  (save-excursion
    (goto-char (point-min))
    (let* ((exec (get-text-property (point) 'key-group-executor))
           (exec-alist (and exec `((,exec . ,(point))))))
      (cl-do nil ((eobp) (nreverse exec-alist))
        (when (not (eq exec (get-text-property (point) 'key-group-executor)))
          (setq exec (get-text-property (point) 'key-group-executor))
          (when exec (push (cons exec (point)) exec-alist)))
        (forward-char)))))

;;; Draw Buffer

(defun makey-key-mode-draw-header (header)
  "Draw a header with the correct face."
  (insert (propertize header 'face 'makey-key-mode-header-face) "\n"))

(defvar makey-key-mode-args-in-cols nil
  "When true, draw arguments in columns as with switches and options.")

(defun makey-key-mode-draw-args (args hash-table)
  "Draw the args part of the menu."
  (makey-key-mode-draw-buttons
   "Args"
   args
   (lambda (x)
     (format "(%s) %s"
             (nth 2 x)
             (propertize (gethash (nth 2 x) hash-table "")
                         'face 'makey-key-mode-args-face)))
   (not makey-key-mode-args-in-cols)))

(defun makey-key-mode-draw-switches (switches)
  "Draw the switches part of the menu."
  (makey-key-mode-draw-buttons
   "Switches"
   switches
   (lambda (x)
     (format "(%s)" (let ((s (nth 2 x)))
                      (if (member s makey-key-mode-current-options)
                          (propertize s 'face 'makey-key-mode-switch-face)
                        s))))))

(defun makey-key-mode-draw-actions (actions)
  "Draw the actions part of the menu."
  (makey-key-mode-draw-buttons "Actions" actions nil))

(defun makey-key-mode-draw-buttons (section xs maker
                                            &optional one-col-each)
  (when xs
    (makey-key-mode-draw-header section)
    (makey-key-mode-draw-in-cols
     (mapcar (lambda (x)
               (let* ((head (propertize (car x) 'face 'makey-key-mode-button-face))
                      (desc (nth 1 x))
                      (more (and maker (funcall maker x)))
                      (text (format " %s: %s%s%s"
                                    head desc (if more " " "") (or more ""))))
                 (propertize text 'key-group-executor (car x))))
             xs)
     one-col-each)))

(defun makey-key-mode-draw-in-cols (strings one-col-each)
  "Given a list of strings, print in columns (using `insert').
If ONE-COL-EACH is true then don't columify, but rather, draw
each item on one line."
  (let ((longest-act (apply 'max (mapcar 'length strings))))
    (while strings
      (let ((str (car strings)))
        (let ((padding (make-string (- (+ longest-act 3) (length str)) ? )))
          (insert str)
          (if (or one-col-each
                  (and (> (+ (length padding) ;
                             (current-column)
                             longest-act)
                          (window-width))
                       (cdr strings)))
              (insert "\n")
            (insert padding))))
      (setq strings (cdr strings))))
  (insert "\n"))

(defun makey-key-mode-draw (for-group)
  "Draw actions, switches and parameters.
Return the point before the actions part, if any, nil otherwise."
  (let* ((options (makey-key-mode-options-for-group for-group))
         (switches (cdr (assoc 'switches options)))
         (arguments (cdr (assoc 'arguments options)))
         (lisp-variables (cdr (assoc 'lisp-variables options)))
         (description (cdr (assoc 'description options)))
         (actions (cdr (assoc 'actions options)))
         (p nil))
    (makey-key-mode-draw-switches switches)
    (makey-key-mode-draw-args arguments makey-key-mode-current-args)
    (makey-key-mode-draw-args lisp-variables makey-key-mode-current-variables)
    (when actions (setq p (point-marker)))
    (makey-key-mode-draw-actions actions)
    (setq header-line-format description)
    (insert "\n")
    p))

;;; Generate Groups

(defun makey-key-mode-de-generate (group)
  "Unbind the function for GROUP."
  (fmakunbound
   (intern (concat "makey-key-mode-popup-" (symbol-name group)))))

(defun makey-key-mode-generate (group-name group-details)
  "Generate the key-group-name menu for GROUP."
  (let ((opts group-details))
    (eval
     `(defun ,(intern (concat "makey-key-mode-options-for-" (symbol-name group-name))) nil
        ,(concat "Options menu helper function for " (symbol-name group-name))
        ',group-details))
    (eval
     `(defun ,(intern (concat "makey-key-mode-popup-" (symbol-name group-name))) nil
        ,(concat "Key menu for " (symbol-name group-name))
        (interactive)
        (makey-key-mode
         (quote ,group-name)
         ;; As a tempory kludge it is okay to do this here.
         ,(cl-case group-name
            (logging
             '(list "--graph"))
            (diff-options
             '(when (local-variable-p 'makey-diff-options)
                makey-diff-options))))))))

(defun makey-initialize-key-groups (key-group)
  "Initializes KEY-GROUP and creates all the relevant interactive commands."
  (setq makey-key-mode-keymaps nil)
  (mapc (lambda (g)
          (makey-key-mode-generate (car g) (cdr g)))
        key-group))

;;; this initializes the default Magit popups.
;(makey-initialize-key-groups makey-key-mode-groups)

(makey-initialize-key-groups '((test
                               (description "Test Description for `ls'")
                               (man-page "ls")
                               (actions
                                ("l" "Long Listing Format" nil)
                                ("s" "Short Listing Format" nil))
                               (switches
                                ("-a" "Show entries starting with .")
                                ("-h" "Print sizes in human readable format"))
                               (arguments
                                ("-fo" "format across" "--format="
                                 (lambda (dummy) (interactive)
                                   (ido-completing-read '("across" "commas" "horizontal" "long"
                                                          "single-column" "verbose" "vertical")))))
                               )))

;;;###autoload (mapc (lambda (g) (eval `(autoload ',(intern (concat "makey-key-mode-popup-" (symbol-name (car g)))) "makey-key-mode" ,(concat "Key menu for " (symbol-name (car g))) t))) makey-key-mode-groups)

(provide 'makey-key-mode)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; makey-key-mode.el ends here
