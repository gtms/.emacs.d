;;; init.el --- gtms personal Emacs configuration
;;
;; Copyright (c) 2018 Gil Tomás
;;
;; Author: Gil Tomás <gil.tms@gmail.com>
;; URL: https://github.com/gtms/emacs.d
;; Keywords: convenience

;; This file is not part of GNU Emacs.

;;; Commentary:

;; My personal Emacs configuration is held in the adjacent file config.org in
;; the form of literate programming (an explanation of the program's logic in
;; org-mode is interspersed with snippets of emacs lisp).
;;
;; The present init.el file contains instructions to efficiently untangle all
;; eligible lisp code from config.org into a new file config.el.  Only emacs
;; lisp snippets not marked as :tangle no and not labelled with the TODO marker
;; CANCELLED are extracted.  Once tangled, the config.el file is then loaded.
;;
;; This file contains code by Holger Schurig originally taken on 21Sep2016 from
;; here: http://www.holgerschurig.de/en/emacs-efficiently-untangling-elisp/

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

(defvar my-start-time (current-time)
  "Time when loading of personal configurations was started.")

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p "custom.el")
  (load custom-file))

;; This is GPLv2. If you still don't know the details, read
;; http://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html

(defun my-tangle-section-canceled ()
  "Return t if the current section header was CANCELLED, else nil."
  (save-excursion
    (if (re-search-backward "^\\*+\\s-+\\(.*?\\)?\\s-*$" nil t)
        (string-prefix-p "CANCELLED" (match-string 1))
      nil)))

;; This uses partially derived code from ob-core.el. So this snippet
;; is GPLv3 or later. If you still don't know the details, read
;; http://www.gnu.org/licenses/

(defun my-tangle-config-org (orgfile elfile)
  "This function will write all source blocks from =config.org= into
=config.el= that are ...

- not marked as :tangle no
- have a source-code of =emacs-lisp=
- doesn't have the todo-marker CANCELLED"
  (let* ((body-list ())
         (gc-cons-threshold most-positive-fixnum)
         (org-babel-src-block-regexp   (concat
                                        ;; (1) indentation                 (2) lang
                                        "^\\([ \t]*\\)#\\+begin_src[ \t]+\\([^ \f\t\n\r\v]+\\)[ \t]*"
                                        ;; (3) switches
                                        "\\([^\":\n]*\"[^\"\n*]*\"[^\":\n]*\\|[^\":\n]*\\)"
                                        ;; (4) header arguments
                                        "\\([^\n]*\\)\n"
                                        ;; (5) body
                                        "\\([^\000]*?\n\\)??[ \t]*#\\+end_src")))
    (with-temp-buffer
      (insert-file-contents orgfile)
      (goto-char (point-min))
      (while (re-search-forward org-babel-src-block-regexp nil t)
        (let ((lang (match-string 2))
              (args (match-string 4))
              (body (match-string 5))
              (canc (my-tangle-section-canceled)))
          (when (and (string= lang "emacs-lisp")
                     (not (string-match-p ":tangle\\s-+no" args))
                     (not canc))
            (add-to-list 'body-list body)))))
    (with-temp-file elfile
      (insert
       (format ";; Don't edit this file, edit %s instead ...\n\n" orgfile))
      (apply 'insert (reverse body-list)))
    (message "Wrote %s ..." elfile)))

;; This is GPLv2. If you still don't know the details, read
;; http://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html

(let ((orgfile (concat user-emacs-directory "config.org"))
      (elfile (concat user-emacs-directory "config.el")))
  (when (or (not (file-exists-p elfile))
            (file-newer-than-file-p orgfile elfile))
    (my-tangle-config-org orgfile elfile))
  (load-file elfile))

(message "Start up time %.2fs."
         (float-time (time-subtract (current-time) my-start-time)))

;;; untangle.el ends here
