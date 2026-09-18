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
      initial-scratch-message nil
      load-prefer-newer t)

;;; early-init.el ends here
