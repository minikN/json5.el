(require 'treesit)
(require 'rx)

(declare-function treesit-parser-create "treesit.c")
(declare-function treesit-induce-sparse-tree "treesit.c")
(declare-function treesit-node-start "treesit.c")
(declare-function treesit-node-type "treesit.c")
(declare-function treesit-node-child-by-field-name "treesit.c")


(defcustom json5-ts-mode-indent-offset 2
  "Number of spaces for each indentation step in `json-ts-mode'."
  :version "29.1"
  :type 'integer
  :safe 'integerp
  :group 'json5)

(defvar json5-ts-mode--syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_  "_"     table)
    (modify-syntax-entry ?\\ "\\"    table)
    (modify-syntax-entry ?+  "."     table)
    (modify-syntax-entry ?-  "."     table)
    (modify-syntax-entry ?=  "."     table)
    (modify-syntax-entry ?%  "."     table)
    (modify-syntax-entry ?<  "."     table)
    (modify-syntax-entry ?>  "."     table)
    (modify-syntax-entry ?&  "."     table)
    (modify-syntax-entry ?|  "."     table)
    (modify-syntax-entry ?\' "\""    table)
    ;(modify-syntax-entry ?\" "\""    table)
    (modify-syntax-entry ?\240 "."   table)
    (modify-syntax-entry ?/  ". 124b" table)
    (modify-syntax-entry ?*  ". 23"   table)
    (modify-syntax-entry ?\n "> b"  table)
    (modify-syntax-entry ?\^m "> b" table)
    table)
  "Syntax table for `json-ts-mode'.")


(defvar json5-ts--indent-rules
  `((json5
     ((node-is "}") parent-bol 0)
     ((node-is ")") parent-bol 0)
     ((node-is "]") parent-bol 0)
     ((parent-is "object") parent-bol json5-ts-mode-indent-offset)
     ((parent-is "array") parent-bol json5-ts-mode-indent-offset))))

(defvar json5-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :language 'json5
   :feature 'comment
   '((comment) @font-lock-comment-face)

   :language 'json5
   :feature 'string
   '((string) @font-lock-string-face)

   :language 'json5
   :feature 'bracket
   '((["[" "]" "{" "}"]) @font-lock-bracket-face)

   ;:language 'json5
   ;:feature 'constant
   ;'((member: value: "true") @font-lock-constant-face)

   :language 'json5
   :feature 'identifier
   '((identifier) @font-lock-property-use-face)

   :language 'json5
   :feature 'delimiter
   '((["," ":"]) @font-lock-delimiter-face)

   :language 'json5
   :feature 'number
   '((number) @font-lock-number-face)

   :language 'json5
   :feature 'escape-sequence
   :override t
   '((escape_sequence) @font-lock-escape-face)

   :language 'json5
   :feature 'error
   :override t
   '((ERROR) @font-lock-warning-face))
  "Font-lock settings for JSON5.")

(defun json5-ts-mode--defun-name (node)
  "Return the defun name of NODE.
Return nil if there is no name or if NODE is not a defun node."
  (pcase (treesit-node-type node)
    ("identifier" node)))

;;;###autoload
(define-derived-mode json5-ts-mode prog-mode "JSON5"
  "Major mode for editing JSON, powered by tree-sitter."
  :group 'json5
  :syntax-table json5-ts-mode--syntax-table

  (unless (treesit-ready-p 'json5)
    (error "Tree-sitter for JSON5 isn't available"))

  (treesit-parser-create 'json5)

  ;; Comments.
  (setq-local comment-start "// ")
  (setq-local comment-start-skip "\\(?://+\\|/\\*+\\)\\s *")
  (setq-local comment-end "")

  ;; Electric
  (setq-local electric-indent-chars
              (append "{}():;," electric-indent-chars))

  ;; Indent.
  (setq-local treesit-simple-indent-rules json5-ts--indent-rules)

  ;; Navigation.
  (setq-local treesit-defun-type-regexp
              (rx (or "identifier" "object")))
  (setq-local treesit-defun-name-function #'json5-ts-mode--defun-name)

  ;;(setq-local treesit-thing-settings
  ;;            `((json
  ;;               (sentence "pair"))))

  ;; Font-lock.
  (setq-local treesit-font-lock-settings json5-ts-mode--font-lock-settings)
  (setq-local treesit-font-lock-feature-list
              '((comment constant number member identifier string)
                (escape-sequence)
                (bracket delimiter error)))

  ;; Imenu.
  ;;(setq-local treesit-simple-imenu-settings
  ;;            '((nil "\\`pair\\'" nil nil)))

  (treesit-major-mode-setup))

(if (treesit-ready-p 'json5)
    (add-to-list 'auto-mode-alist
                 '("\\.json5\\'" . json5-ts-mode)))

(provide 'json5-ts-mode)
