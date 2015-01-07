;;; nit-mode.el --- Nit language editing mode        -*- lexical-binding: t; -*-

;; Copyright (C) 2015  Denis Martinez

;; Author:  <denis.martinez@live.com>
;; Keywords: languages

;; Licensed to the Apache Software Foundation (ASF) under one
;; or more contributor license agreements.  See the NOTICE file
;; distributed with this work for additional information
;; regarding copyright ownership.  The ASF licenses this file
;; to you under the Apache License, Version 2.0 (the
;; "License"); you may not use this file except in compliance
;; with the License.  You may obtain a copy of the License at

;;   http://www.apache.org/licenses/LICENSE-2.0

;; Unless required by applicable law or agreed to in writing,
;; software distributed under the License is distributed on an
;; "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
;; KIND, either express or implied.  See the License for the
;; specific language governing permissions and limitations
;; under the License.

;;; Commentary:

;; 2015-06-01: version 0.1 (beta)
;;  initial release with indentation, syntax coloring and comments
;;  ok with many nit programs already, needs more testing.

;;; Code:

;;;###autoload (add-to-list 'auto-mode-alist '("\\.nit\\'" . nit-mode))

;;;###autoload
(defvar nit-mode-hook
  nil)

(defgroup nit nil
  "Nit language editing mode"
  :prefix "nit-"
  :group 'languages)

(defcustom nit-basic-offset
  default-tab-width
  "Width of an indentation in number of spaces.
By default, this is equal to the width of a tab character."
  :type 'integer
  :group 'nit)

(defvar nit-mode-map
  (let ((map (make-keymap)))
    ;; (define-key map ...)
    map)
  "Keymap for nit major mode")

(defconst nit-keywords
  '("init" "end" "not" "var" "do" "then" "else" "loop" "is"
    "end"
    "abstract" "intern" "new"
    "private" "public" "protected" "intrude" "readable" "writable" "redef"
    "if" "while" "for" "and" "or" "in" "as" "isa" "once" "break" "continue" "return"
    "nullable"
    "special"
    ; "FIXME" "NOTE" "TODO" "XXX" "contained" ; TODO: how to font-lock inside comments?
    ))

(defconst nit-constants
  '("null"
    "true" "false"
    "self"))

(defconst nit-basic-types
  '("Object" "Int" "Float" "String" "Bool" "Array" "Range" "HashMap"))

(defconst nit-builtins
  '("super"
    "assert"
    "abort"))

(defvar nit-font-lock-keywords
  `(;; -> name of class/interface
    ("\\_<\\(class\\|interface\\)[ \t]+\\([[:alpha:]][[:alnum:]_]*\\)"
     (1 font-lock-keyword-face)
     (2 font-lock-type-face))
    ;; -> name of function
    ("\\_<\\(fun\\)[ \t]+\\([[:alpha:]][[:alnum:]_]*\\)"
     (1 font-lock-keyword-face)
     (2 font-lock-function-name-face))
    ;; -> name of a variable (with var but no type)
    ("\\_<\\(var\\)[ \t]+\\([[:alpha:]][[:alnum:]_]*\\)"
     (1 font-lock-keyword-face)
     (2 font-lock-variable-name-face))
    ;; -> name of a type instanciated with new
    ("\\_<\\(new\\)[ \t]+\\([[:alpha:]][[:alnum:]_]*\\)"
     (1 font-lock-keyword-face)
     (2 font-lock-type-face))
    ;; -> anIdentifier: another
    ;;  (variable with type, or bounded generic formal parameter)
    ("\\_<\\([[:alpha:]][[:alnum:]_]*\\)[ \t]*:[ \t]*\\([[:alpha:]][[:alnum:]_]*\\)"
     (1 font-lock-variable-name-face)
     (2 font-lock-type-face))
    ;; highlight some keywords, types, constants, etc.
    (,(regexp-opt nit-keywords 'words) . font-lock-keyword-face)
    (,(regexp-opt nit-basic-types 'words) . font-lock-type-face)
    (,(regexp-opt nit-constants 'words) . font-lock-constant-face)
    (,(regexp-opt nit-builtins 'words) . font-lock-builtin-face)))

(defvar nit-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?\# "<" st)
    (modify-syntax-entry ?\n ">#" st)
    (modify-syntax-entry ?_ "_" st)
    st))

(defun nit-re-line-anchor (r)
  (concat r "[ \t]*\\(#.*\\)?$"))

(defun nit-calculate-indent (&optional as-normal-stmt)
  (let (cur-indent)
    (save-excursion
      (beginning-of-line)
      (skip-chars-forward " \t")
      ;; block terminating syntax
      (when (and (looking-at "\\(end\\|else\\)\\_>") (not as-normal-stmt))
        ;; compute indentation as if a normal statement were there instead, substract one level
        (setq cur-indent (- (nit-calculate-indent t) nit-basic-offset)))
      ;; normal statement
      (loop while (not cur-indent) do
            ;; go up until finding the previous line of actual code
            (forward-line -1)
            (cond ((bobp) (setq cur-indent 0))
                  ((looking-at (nit-re-line-anchor "[ \t]*")) ()) ;; empty line, proceed
                  ;; TODO also, the case when we are in multiline string
                  ((or (looking-at (nit-re-line-anchor ".*\\_<\\(do\\|then\\|else\\|loop\\)"))
                       (looking-at "\\(\\(redef\\|extern\\|abstract\\|public\\|private\\)[ \t]+\\)*\\(class\\|interface\\)\\_>"))
                    ;; preceded by indenting statement
                   (setq cur-indent
                         (+ (current-indentation) nit-basic-offset)))
                  (t ;; same indentation level as previous
                   (setq cur-indent (current-indentation))))))
    cur-indent))

(defun nit-indent-line ()
  "Indent current line as nit code"
  (interactive)
  (let ((cur-indent (nit-calculate-indent)))
    (if cur-indent
        (indent-line-to
         (if (> cur-indent 0) cur-indent 0))
      (indent-line-to 0))))

;;;###autoload
(define-derived-mode nit-mode fundamental-mode "nit"
  "Major mode for editing nit language files."
  (set (make-local-variable 'font-lock-defaults) '(nit-font-lock-keywords nil t))
  (set (make-local-variable 'indent-line-function) 'nit-indent-line)
  (set (make-local-variable 'comment-start) "#"))

(provide 'nit-mode)
;;; nit-mode.el ends here
