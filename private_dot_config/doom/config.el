;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.


;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Basic Doom settings
(setq doom-theme 'doom-one)
(setq display-line-numbers-type t)
(setq doom-font (font-spec :family "monospace" :size 16))
(setq org-directory (expand-file-name "~/org/"))


(after! org
  ;; explicit paths (avoid nil)
  (defvar my-org-dir (expand-file-name "/home/slap/org/"))
  (setq org-agenda-files
        (list (concat my-org-dir "inbox.org")
              (concat my-org-dir "2026-spring.org")))
  (setq org-default-notes-file (concat my-org-dir "inbox.org"))

  ;; capture template using explicit absolute path
  (setq org-capture-templates
        '(("t" "Todo" entry
           (file+headline "/home/slap/org/inbox.org" "Tasks")
           "* TODO [#B] %?\n  %U\n")))

  ;; refile settings
  (setq org-refile-targets '((org-agenda-files :maxlevel . 4)))
  (setq org-refile-use-outline-path 'file)
  (setq org-outline-path-complete-in-steps nil)

;; Custom agenda commands
(setq org-deadline-warning-days 0) ;; no longer warns about deadlines x days away
(setq org-agenda-custom-commands
      '(("c" "Simple Agenda"
         (
          ;; 1) Overdue deadlines
          (tags-todo "+DEADLINE<\"<today>\""
                     ((org-agenda-overriding-header "⚠️ Overdue Deadlines")
                      (org-agenda-sorting-strategy '(priority-down deadline-up))))

          ;; 2) Next 10 days, sorted by priority
          (agenda ""
                  ((org-agenda-start-day "-2d")   ;; start 5 days before today
                   (org-agenda-span 10)
                   (org-agenda-sorting-strategy '(time-up deadline-up scheduled-up priority-down))
                   (org-agenda-overriding-header "📅 Multi-day Agenda View")))


          ;; 3) Unscheduled TODOs
          (alltodo ""
                   ((org-agenda-skip-function '(or (org-agenda-skip-entry-if 'scheduled 'deadline)))
                    (org-agenda-overriding-header "📝 Unscheduled / Misc TODOs")))
          ))))

; ;; sorting preferences
; (setq org-agenda-sorting-strategy
;       '((agenda priority-down time-up)
;         (todo priority-down)
;         (tags priority-down)))
)
