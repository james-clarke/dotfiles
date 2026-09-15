;;; init.el --- lean evil + vertico + eglot -*- lexical-binding: t -*-

(when (< emacs-major-version 30) (error "Emacs 30+ required"))

;;; ---------- packages ----------
(require 'package)
(setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")
                         ("melpa" . "https://melpa.org/packages/"))
      package-archive-priorities '(("gnu" . 3) ("nongnu" . 2) ("melpa" . 1))
      use-package-always-ensure t)
(package-initialize)
(unless package-archive-contents (package-refresh-contents))

(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file 'noerror 'nomessage)

;;; ---------- path (daemon/launchd never see the shell PATH) ----------
(dolist (dir '("~/.local/share/mise/shims" "~/.local/bin"))
  (let ((d (expand-file-name dir)))
    (when (file-directory-p d)
      (add-to-list 'exec-path d)
      (setenv "PATH" (concat d path-separator (getenv "PATH"))))))

;;; ---------- core ----------
(use-package emacs
  :ensure nil
  :custom
  (ring-bell-function #'ignore)
  (use-short-answers t)
  (create-lockfiles nil)
  (make-backup-files nil)
  (auto-save-default nil)
  (require-final-newline t)
  (indent-tabs-mode nil)
  (tab-width 4)
  (fill-column 100)
  (sentence-end-double-space nil)
  (scroll-conservatively 101)
  (scroll-margin 4)
  (read-process-output-max (* 4 1024 1024))
  (enable-recursive-minibuffers t)
  (read-extended-command-predicate #'command-completion-default-include-p)
  (minibuffer-prompt-properties '(read-only t cursor-intangible t face minibuffer-prompt))
  (tab-always-indent 'complete)
  (text-mode-ispell-word-completion nil)
  (delete-by-moving-to-trash t)
  (confirm-kill-processes nil)
  (display-line-numbers-type 'relative)
  (frame-title-format '("%b"))
  (uniquify-buffer-name-style 'forward)
  (global-auto-revert-non-file-buffers t)
  (auto-revert-verbose nil)
  (recentf-max-saved-items 200)
  (dired-dwim-target t)
  (dired-kill-when-opening-new-dired-buffer t)
  (dired-listing-switches (if (eq system-type 'darwin) "-alh" "-alh --group-directories-first"))
  (which-key-idle-delay 0.4)
  (compilation-scroll-output 'first-error)
  :config
  (global-auto-revert-mode)
  (savehist-mode)
  (recentf-mode)
  (save-place-mode)
  (electric-pair-mode)
  (delete-selection-mode)
  (column-number-mode)
  (pixel-scroll-precision-mode)
  (repeat-mode)
  (which-key-mode)
  (editorconfig-mode)
  (global-so-long-mode)
  (winner-mode)
  (blink-cursor-mode -1)
  (setq-default cursor-in-non-selected-windows nil truncate-lines t)
  (dolist (h '(prog-mode-hook text-mode-hook conf-mode-hook))
    (add-hook h #'display-line-numbers-mode)
    (add-hook h #'hl-line-mode))
  (add-hook 'prog-mode-hook #'subword-mode)
  (add-hook 'emacs-lisp-mode-hook #'flymake-mode)
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)
  (keymap-set minibuffer-mode-map "<escape>" #'abort-minibuffers)
  (unless noninteractive
    (xterm-mouse-mode)
    (require 'server)
    (unless (server-running-p) (server-start))))

(use-package gcmh
  :custom
  (gcmh-idle-delay 'auto)
  (gcmh-auto-idle-delay-factor 10)
  (gcmh-high-cons-threshold (* 64 1024 1024))
  :config (gcmh-mode 1))

;;; ---------- evil ----------
(use-package evil
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-want-C-i-jump nil
        evil-want-Y-yank-to-eol t
        evil-undo-system 'undo-redo
        evil-respect-visual-line-mode t
        evil-split-window-below t
        evil-vsplit-window-right t
        evil-search-module 'evil-search
        evil-ex-search-vim-style-regexp t)
  :config
  (defvar evil-mode-buffers nil)
  (evil-mode 1)
  (evil-set-leader '(normal visual) (kbd "SPC"))
  (evil-define-key 'normal 'global (kbd "gcc") #'comment-line (kbd "K") #'eldoc)
  (evil-define-key 'visual 'global (kbd "gc") #'comment-dwim))

(use-package evil-collection
  :after evil
  :custom
  (evil-collection-want-unimpaired-p nil)
  (evil-collection-key-blacklist '("SPC"))
  :config (evil-collection-init))

(use-package evil-surround
  :after evil
  :config (global-evil-surround-mode 1))

;;; ---------- leader ----------
(require 'project)
(defvar-keymap dot-leader-map
  "SPC" #'execute-extended-command
  ","   #'consult-buffer
  "."   #'find-file
  "/"   #'consult-ripgrep
  "u"   #'universal-argument
  "f f" #'find-file
  "f r" #'consult-recent-file
  "f s" #'save-buffer
  "f S" #'save-some-buffers
  "f d" #'dired-jump
  "f i" (lambda () (interactive) (find-file user-init-file))
  "b b" #'consult-buffer
  "b d" #'kill-current-buffer
  "b n" #'next-buffer
  "b p" #'previous-buffer
  "b r" #'revert-buffer-quick
  "b s" #'scratch-buffer
  "b u" #'vundo
  "p"   project-prefix-map
  "w"   evil-window-map
  "h"   help-map
  "g g" #'magit-status
  "g b" #'magit-blame-addition
  "g l" #'magit-log-current
  "g f" #'magit-file-dispatch
  "g n" #'diff-hl-next-hunk
  "g p" #'diff-hl-previous-hunk
  "g r" #'diff-hl-revert-hunk
  "s s" #'consult-line
  "s p" #'consult-ripgrep
  "s i" #'consult-imenu
  "s o" #'consult-outline
  "s m" #'consult-mark
  "s y" #'consult-yank-pop
  "l a" #'eglot-code-actions
  "l r" #'eglot-rename
  "l f" #'eglot-format
  "l d" #'xref-find-definitions
  "l R" #'xref-find-references
  "l i" #'eglot-find-implementation
  "l s" #'consult-eglot-symbols
  "l e" #'eglot
  "l q" #'eglot-shutdown
  "e n" #'flymake-goto-next-error
  "e p" #'flymake-goto-prev-error
  "e l" #'consult-flymake
  "e b" #'flymake-show-buffer-diagnostics
  "c c" #'project-compile
  "c r" #'recompile
  "o t" #'eat-project
  "o T" #'eat
  "o d" #'dired
  "t t" #'modus-themes-toggle
  "t l" #'display-line-numbers-mode
  "t w" #'visual-line-mode
  "t f" #'toggle-frame-fullscreen
  "t p" #'popper-toggle
  "t P" #'popper-cycle
  "a a" #'claude-code-ide-menu
  "a c" #'claude-code-ide
  "a t" #'claude-code-ide-toggle
  "a s" #'claude-code-ide-send-prompt
  "a r" #'claude-code-ide-insert-at-mentioned
  "a C" #'claude-code-ide-continue
  "a R" #'claude-code-ide-resume
  "a q" #'claude-code-ide-stop
  "q q" #'save-buffers-kill-terminal
  "q f" #'delete-frame)
(evil-define-key '(normal visual) 'global (kbd "<leader>") dot-leader-map)
(which-key-add-keymap-based-replacements dot-leader-map
  "f" "file" "b" "buffer" "p" "project" "w" "window" "h" "help" "g" "git"
  "s" "search" "l" "lsp" "e" "errors" "c" "compile" "o" "open" "t" "toggle"
  "a" "ai" "q" "quit")

;;; ---------- completion ----------
(use-package vertico
  :custom (vertico-cycle t) (vertico-count 15)
  :bind (:map vertico-map ("C-j" . vertico-next) ("C-k" . vertico-previous))
  :init (vertico-mode))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia :init (marginalia-mode))

(use-package consult
  :custom
  (consult-narrow-key "<")
  (xref-show-xrefs-function #'consult-xref)
  (xref-show-definitions-function #'consult-xref)
  :bind (("C-s" . consult-line)
         ([remap switch-to-buffer] . consult-buffer)
         ([remap goto-line] . consult-goto-line)
         ([remap yank-pop] . consult-yank-pop)
         ([remap imenu] . consult-imenu)
         ([remap project-switch-to-buffer] . consult-project-buffer)
         ([remap recentf-open] . consult-recent-file)))

(use-package consult-eglot :after (consult eglot))

(use-package embark
  :custom (prefix-help-command #'embark-prefix-help-command)
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim)
         ([remap describe-bindings] . embark-bindings)))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.1)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  (corfu-preselect 'prompt)
  :bind (:map corfu-map ("C-j" . corfu-next) ("C-k" . corfu-previous))
  :init (global-corfu-mode)
  :config (corfu-popupinfo-mode))

(use-package corfu-terminal :if (< emacs-major-version 31) :after corfu :config (corfu-terminal-mode))

(use-package cape
  :init
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-dabbrev))

(use-package tempel
  :bind (("M-+" . tempel-complete) ("M-*" . tempel-insert))
  :hook ((prog-mode text-mode conf-mode) . dot/tempel-capf)
  :init
  (defun dot/tempel-capf ()
    (add-hook 'completion-at-point-functions #'tempel-expand -1 t)))

;;; ---------- editing ----------
(use-package vundo :custom (vundo-glyph-alist vundo-unicode-symbols))
(use-package hl-todo :hook (prog-mode . hl-todo-mode))

(use-package popper
  :custom
  (popper-reference-buffers
   '("\\*Messages\\*" "\\*Warnings\\*" "Output\\*$" "\\*eat\\*" "\\*Async Shell Command\\*"
     help-mode compilation-mode flymake-diagnostics-buffer-mode))
  :init
  (popper-mode)
  (popper-echo-mode))

;;; ---------- languages ----------
(use-package eglot
  :ensure nil
  :hook ((python-base-mode js-base-mode typescript-ts-base-mode rust-ts-mode go-ts-mode
                           c-ts-base-mode bash-ts-mode ruby-ts-mode) . eglot-ensure)
  :custom
  (eglot-autoshutdown t)
  (eglot-events-buffer-config '(:size 0))
  (eglot-extend-to-xref t))

(use-package treesit-auto
  :custom (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

(use-package apheleia :config (apheleia-global-mode))
(use-package envrc :config (envrc-global-mode))

(use-package markdown-mode
  :mode ("\\.md\\'" . gfm-mode)
  :custom (markdown-fontify-code-blocks-natively t))

;;; ---------- git ----------
(use-package magit
  :custom
  (magit-diff-refine-hunk t)
  (magit-save-repository-buffers 'dontask)
  :bind ("C-x g" . magit-status))

(use-package diff-hl
  :hook (magit-post-refresh . diff-hl-magit-post-refresh)
  :init (global-diff-hl-mode)
  :config (diff-hl-flydiff-mode))

;;; ---------- tools ----------
(use-package eat
  :custom (eat-kill-buffer-on-exit t)
  :hook (eshell-load . eat-eshell-mode))

(use-package wgrep :custom (wgrep-auto-save-buffer t))

;;; ---------- ai: claude code inside emacs ----------
(use-package ediff
  :ensure nil
  :custom
  (ediff-window-setup-function #'ediff-setup-windows-plain)
  (ediff-split-window-function #'split-window-horizontally))

(use-package claude-code-ide
  :vc (:url "https://github.com/manzaltu/claude-code-ide.el" :rev :newest)
  :custom (claude-code-ide-terminal-backend 'eat)
  :config (claude-code-ide-emacs-tools-setup))

(use-package minuet
  :hook (prog-mode . dot/minuet-on)
  :bind (:map evil-insert-state-map ("M-i" . minuet-show-suggestion)
              :map minuet-active-mode-map
              ("M-a" . minuet-accept-suggestion-line)
              ("M-y" . minuet-accept-suggestion)
              ("M-e" . minuet-dismiss-suggestion)
              ("M-n" . minuet-next-suggestion)
              ("M-p" . minuet-previous-suggestion))
  :custom
  (minuet-provider 'openai-compatible)
  (minuet-n-completions 1)
  (minuet-auto-suggestion-throttle-delay 1.5)
  (minuet-auto-suggestion-block-predicates
   '(minuet-evil-not-insert-state-p dot/minuet-no-key-p dot/minuet-corfu-open-p dot/minuet-mid-line-p))
  :init
  (defconst dot/minuet-host "openrouter.ai")
  (defun dot/minuet-no-key-p ()
    (not (auth-source-search :host dot/minuet-host :max 1)))
  (defun dot/minuet-key ()
    "The OpenRouter key from auth-source. First use asks for it and offers to save it to ~/.authinfo."
    (when-let* ((entry (car (auth-source-search :host dot/minuet-host :user "apikey" :max 1 :create t)))
                (secret (plist-get entry :secret)))
      (when-let* ((save (plist-get entry :save-function)))
        (funcall save)
        (when (file-exists-p "~/.authinfo") (set-file-modes (expand-file-name "~/.authinfo") #o600)))
      (if (functionp secret) (funcall secret) secret)))
  (defvar dot/minuet-told nil)
  (defun dot/minuet-on ()
    (minuet-auto-suggestion-mode)
    (when (and (not dot/minuet-told) (dot/minuet-no-key-p))
      (setq dot/minuet-told t)
      (message "minuet: no OpenRouter API key yet; M-i in insert state asks for one")))
  (defun dot/minuet-corfu-open-p () completion-in-region-mode)
  (defun dot/minuet-mid-line-p () (not (eolp)))
  (defun dot/minuet-chat-tail ()
    "Last 60 lines of this project's Claude Code window, or nil when it is not open."
    (when-let* ((buf (and (fboundp 'claude-code-ide--get-buffer-name)
                          (get-buffer (claude-code-ide--get-buffer-name)))))
      (with-current-buffer buf
        (save-excursion
          (goto-char (point-max))
          (forward-line -60)
          (buffer-substring-no-properties (point) (point-max))))))
  (defun dot/minuet-prompt ()
    (concat minuet-default-prompt-prefix-first
            (when-let* ((chat (dot/minuet-chat-tail)))
              (concat "\nThe user is discussing this code with an assistant. The end of that conversation follows; use it for intent, names and conventions only.\n<conversation>\n"
                      chat "\n</conversation>\n"))))
  :config
  (require 'auth-source)
  (setq minuet-openai-compatible-options
        (plist-put minuet-openai-compatible-options :model "google/gemini-2.5-flash-lite"))
  (setq minuet-openai-compatible-options
        (plist-put minuet-openai-compatible-options :api-key #'dot/minuet-key))
  (let ((system (plist-get minuet-openai-compatible-options :system)))
    (plist-put system :prompt #'dot/minuet-prompt)
    (plist-put system :guidelines
               (concat minuet-default-guidelines
                       "\n8. Complete only when the surrounding code and the conversation make the next code certain. If you would be guessing at a name, a value or the user's intent, return nothing at all."))
    (plist-put system :n-completions-template "9. Provide at most %d completion items.")))

;;; ---------- ui ----------
(setq modus-themes-italic-constructs t
      modus-themes-bold-constructs t
      modus-themes-to-toggle '(modus-vivendi modus-operandi))
(load-theme 'modus-vivendi t)

(use-package mood-line
  :config
  (setq mood-line-glyph-alist mood-line-glyphs-unicode)
  (mood-line-mode))

(use-package ligature
  :config
  (ligature-set-ligatures
   'prog-mode
   '("->" "->>" "=>" "==" "===" "!=" "!==" "<=" ">=" "&&" "||" "::" ":=" "//" "/*" "*/"
     "++" "--" "<-" "..." "?." "??" "|>" "<|" "<>" "<<" ">>" "__"))
  (global-ligature-mode))

(defun dot/apply-font (&optional frame)
  "Set the default font on FRAME when it is graphical and the font exists."
  (when (and (display-graphic-p frame)
             (find-font (font-spec :family "CommitMono Nerd Font") frame))
    (set-face-attribute 'default frame :family "CommitMono Nerd Font" :height 110)))
(add-hook 'after-make-frame-functions #'dot/apply-font)
(dot/apply-font)

;;; ---------- macOS ----------
(when (eq system-type 'darwin)
  (setopt ns-option-modifier 'meta
          ns-right-option-modifier 'none
          ns-command-modifier 'super
          dired-use-ls-dired nil)
  (use-package exec-path-from-shell
    :custom (exec-path-from-shell-variables '("PATH" "MANPATH" "SSH_AUTH_SOCK"))
    :config (exec-path-from-shell-initialize)))

;;; init.el ends here
