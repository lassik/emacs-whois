;;; whois.el --- extra functionality for WHOIS domain name queries
;;
;; Copyright 2019 Lassi Kortela
;; SPDX-License-Identifier: GPL-3.0-or-later
;; Author: Lassi Kortela <lassi@lassi.io>
;; URL: https://github.com/lassik/emacs-whois
;; Version: 0.1.0
;; Package-Requires: ((emacs "24"))
;; Keywords: network comm
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; This package complements (does not replace) the standard whois
;; functionality of GNU Emacs. It provides:
;;
;; * A `whois-mode' with font-lock highlighting to make whois
;;   responses easier to read.
;;
;; * A `whois-shell' function to make a whois query using the system
;;   whois program instead of Emacs' own (often not up to date) whois
;;   client.
;;
;;; Code:

;; GNU Emacs defines the following variables and functions in
;; net-utils.el.  We will be careful not to step on any of them.
;;
;; defcustom whois-guess-server
;; defcustom whois-reverse-lookup-server
;; defcustom whois-server-list
;; defcustom whois-server-name
;; defcustom whois-server-tld
;;
;; defun whois
;; defun whois-get-tld
;; defun whois-reverse-lookup

(require 'net-utils)

(defconst whois-mode-syntax-table
  (let ((st (make-syntax-table)))
    ;; Treat double quotes as ordinary punctuation, not special string
    ;; delimiters for syntax highlighting.
    (modify-syntax-entry ?\" "." st)
    st))

(defconst whois-mode-font-lock-keywords
  `(;; >>> Last update of whois database: ... <<<
    ("^>>> Last update.*?: .*? <<<$"
     (0 font-lock-type-face))
    ;; Keyword: Value (special case for DNSSEC)
    ("^ *\\(DNSSEC:\\)\\(.*\\)$"
     (1 font-lock-type-face)
     (2 font-lock-function-name-face))
    ;; Keyword: Value (special case for Domain Name, Name Server, etc.)
    ("^ *\\(.*?Name.*?:\\|.*?Server.*?\\)\\(.*\\)$"
     (1 font-lock-type-face)
     (2 font-lock-function-name-face))
    ;; Keyword: Value (generic case)
    ("^ *\\([A-Z][A-Za-z0-9-/ ]+[a-z][A-Za-z0-9-/ ]+:\\)\\(.*\\)$"
     (1 font-lock-type-face)
     (2 font-lock-string-face))
    ;; Date and time in ISO format with timezone
    (,(concat "[12][09][0-9][0-9]-[0-9][0-9]-[0-9][0-9]"
              "T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]"
              "\\(?:Z\\|[+-][0-9][0-9][0-9][0-9]\\)")
     (0 font-lock-preprocessor-face t))
    ;; Email address (or other address using @ syntax)
    ("[A-Za-z0-9.+-]+@[A-Za-z0-9.-]+"
     (0 font-lock-variable-name-face t))
    ;; Web URL
    ("https?://[A-Za-z0-9.:/#?&=_+-]*"
     (0 font-lock-variable-name-face t))))

;;;###autoload
(define-derived-mode whois-mode fundamental-mode "Whois"
  "Major mode for browsing WHOIS domain name registration records."
  :syntax-table whois-mode-syntax-table
  (set (make-local-variable 'paragraph-separate) "[ \t]*$")
  (set (make-local-variable 'paragraph-start) "[ \t]*$")
  (set (make-local-variable 'font-lock-defaults)
       '((whois-mode-font-lock-keywords) nil nil ((?_ . "w")) nil)))

;;;###autoload
(defun whois-shell (object &optional flags)
  "Run whois domain name query on OBJECT using external program.

Optional argument FLAGS gives extra command line arguments for
the whois program."
  (interactive
   (let ((flags (when current-prefix-arg
                  (read-from-minibuffer "Flags for the whois command: "))))
     (list (read-from-minibuffer "Domain name (or other object) for whois: ")
           flags)))
  (let ((flags (or flags "")))
    (switch-to-buffer (get-buffer-create "*Whois*"))
    (unless (equal 'whois-mode major-mode)
      (whois-mode))
    (start-process-shell-command
     "whois" (current-buffer)
     (concat "whois" " " flags " " "--" " " (shell-quote-argument object)))))

(provide 'whois)

;;; whois.el ends here
