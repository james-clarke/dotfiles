;;; early-init.el --- startup tuning -*- lexical-binding: t -*-

(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(defvar dot--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 32 1024 1024)
                  gc-cons-percentage 0.1
                  file-name-handler-alist dot--file-name-handler-alist)))

(setq package-enable-at-startup nil
      frame-resize-pixelwise t
      frame-inhibit-implied-resize t
      window-resize-pixelwise t
      inhibit-startup-screen t
      inhibit-startup-echo-area-message user-login-name
      initial-scratch-message nil
      load-prefer-newer t
      use-dialog-box nil
      native-comp-async-report-warnings-errors 'silent)

(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(setq menu-bar-mode nil tool-bar-mode nil scroll-bar-mode nil)

;;; early-init.el ends here
