;;; bookmarks-menu.el --- Add a Bookmarks menu to the menu bar -*- lexical-binding: t; -*-

;; Author: Andy Rosen <ajr@corp.mlfs.org>
;; URL: https://github.com/ajrosen/bookmarks-menu
;; Version: 20250508.1224
;; Package-Requires: ((emacs "29.1"))
;; Keywords: matching, convenience, bookmark

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; Add a Bookmarks menu to the menu bar.

;; Installation:
;;
;; Add either `(buffers-menu-mode t)', to enable the minor mode, or
;; `(buffers-menu-add-menu)' to your init file.

;; Customization:
;;
;; *Menu Title*
;;
;; You can change the title of the menu to reduce the amount of space
;; the menu occupies in the menu bar.  Not surprisingly the default is
;; "Bookmarks".
;;
;; *Menu Placement*
;;
;; The menu can be placed after any standard menu you choose.
;; 
;; *Jump Target*
;;
;; This controls where bookmarks will appear when selected from the
;; menu.  The choices are `self', `window', and `frame'.  These
;; correspond with the bookmark commands `boookmark-jump',
;; `bookmark-jump-other-window', and `bookmark-jump-other-frame'.
;;
;; *Item Length*
;;
;; By default bookmarks are trimmed to 18 characters in the menu.

;; Commands:
;;
;; There are only three commands: `bookmarks-menu-add-menu',
;; `bookmarks-menu-remove-menu', and `bookmarks-menu-mode'.  Enabling
;; and disabling the minor menu is equivalent to calling the add and
;; remove menu functions.

;;; Code:

(require 'bookmark)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Customization

;;;###autoload
(defgroup bookmarks-menu nil
  "Bookmarks menu in the menu bar."
  :group 'bookmark)

;; bookmarks-menu-title
(defcustom bookmarks-menu-title "Bookmarks"
  "The name of the menu as it appears in the menu bar."
  :tag "Menu Title"
  :group 'bookmarks-menu
  :type '(string))

;; bookmarks-menu-placement
(defcustom bookmarks-menu-placement "buffer"
  "Place the Bookmarks menu after this menu.

If you choose Custom, enter the name of the menu's event.  That is not
necessarily the same as the menu's title.  You can get the event's name
by calling `describe-key-briefly' and selecting an item from the menu.

You will see a \"path\" in the echo area.  The event name is in <angle
brackets>.  E.g., the Buffers menu shows \"<menu-bar> <buffer>
<next-buffer>\".  You would enter \"buffer\" (without the quotation marks)."
  :tag "Menu Placement"
  :group 'bookmarks-menu
  :type '(choice
	  (const :tag "File" :value "file")
	  (const :tag "Edit" :value "edit")
	  (const :tag "Options" :value "options")
	  (const :tag "Buffers" :value "buffer")
	  (const :tag "Tools" :value "tools")
	  (string :tag "Custom")))

;; bookmarks-menu-jump-target
(defcustom bookmarks-menu-jump-target "self"
  "Where to open bookmarks chosen from the menu.

Possible targets are the current window, a new window, or a new frame.
See `bookmark-jump', `bookmark-jump-other-window', or
`bookmark-jump-other-frame'."
  :tag "Jump Target"
  :group 'bookmarks-menu
  :type '(choice
	  (const :tag "Current window" :value "self")
	  (const :tag "Other window" :value "window")
	  (const :tag "Other frame" :value "frame")))

;; bookmarks-menu-item-length
(defcustom bookmarks-menu-item-length 18
  "Maximum length of a bookmark name displayed on the menu.

Use zero for no limit."
  :tag "Item Length"
  :group 'bookmarks-menu
  :type '(natnum))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Variables

;; The menu.  This is the object that will be added to the menu bar.
(defvar bookmarks-menu nil)

;; The menu's path.  Menu items are added to and removed from here.
(defconst bookmarks-menu--path `("menu-bar" ,bookmarks-menu-title))

;; A list containing the bookmark objects that are in the menu.  It is
;; a copy of (bookmark-maybe-sort-alist).  It gets set when bookmarks
;; are added to the menu, and used to check if your bookmarks have
;; changed.
(defvar bookmarks-menu--items-list nil)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Autoloaded functions

;; <menu-bar> <edit> <bookmark>

;;;###autoload
(defun bookmarks-menu-add-menu ()
  "Add a Bookmarks menu to the menu bar."

  (interactive)

  ;; "Bookmarks menu" is just a doc string; it is never referenced.
  (unless bookmarks-menu
    (easy-menu-define bookmarks-menu nil "Bookmarks menu" nil))

  ;; Add our (empty) menu to the menu bar.
  (define-key-after (lookup-key (current-global-map) [menu-bar])
    [bookmarks] (cons bookmarks-menu-title bookmarks-menu) (intern bookmarks-menu-placement))

  ;; Add a separator line to our menu.  Bookmarks will be added before
  ;; this, and "footer" items will be added after it.
  (easy-menu-add-item (current-global-map) bookmarks-menu--path "--")

  ;; Update the menu to populate it.
  (bookmarks-menu--update)

  ;; `bookmark-alist-modification-count' changes whenever the
  ;; bookmarks change.  Watch this variable instead of using
  ;; `menu-bar-update-hook' for performance; the hook is called very
  ;; often.
  (add-variable-watcher 'bookmark-alist-modification-count 'bookmarks-menu--update))

;;;###autoload
(defun bookmarks-menu-remove-menu ()
  "Remove the Bookmarks menu from the menu bar."
  (interactive)

  ;; Stop watching `bookmark-alist-modification-count'.
  (remove-variable-watcher 'bookmark-alist-modification-count 'bookmarks-menu--update)

  ;; Empty our (internal) list of items in the menu.
  (setq bookmarks-menu--items-list nil)

  ;; Setting DEF to `nil' undefines the key.  Adding the optional
  ;; REMOVE argument removes the definition itself.
  (define-key (lookup-key (current-global-map) [menu-bar]) [bookmarks] nil t))

;;;###autoload
(define-minor-mode bookmarks-menu-mode
  "Show a Bookmarks menu in the menu bar."
  :global t
  :interactive (bookmarks-menu-mode)
  :group 'bookmark

  ;; Call -add-menu if enabling, -remove-menu if disabling.
  (if bookmarks-menu-mode (bookmarks-menu-add-menu) (bookmarks-menu-remove-menu)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Internal functions

;; bookmarks-menu--load-bookmarks
(defun bookmarks-menu--load-bookmarks ()
  "If bookmarks have not been loaded from the default place, load them.

Simple wrapper for `bookmark-maybe-load-default-file', but (`interactive') so it
can be called from a menu."
  (interactive)
  (bookmark-maybe-load-default-file))

;; bookmarks-menu--jump
(defun bookmarks-menu--jump (bookmark)
  "Jump to the BOOKMARK.  See `bookmarks-menu-jump-target'."

  ;; If `bookmarks-menu-jump-target' is unbound, or has an unknown
  ;; value, use "self".
  (cond
   ((not (boundp 'bookmarks-menu-jump-target)) (bookmark-jump bookmark))
   ((string-equal bookmarks-menu-jump-target "self") (bookmark-jump bookmark))
   ((string-equal bookmarks-menu-jump-target "frame") (bookmark-jump-other-frame bookmark))
   ((string-equal bookmarks-menu-jump-target "window") (bookmark-jump-other-window bookmark))
   ((bookmark-jump bookmark))))

;; bookmarks-menu--display-name
(defun bookmarks-menu--display-name (bookmark)
  "Return BOOKMARK's name as it should be displayed in the menu."

  ;; Get the bookmark's name and maybe trim it, adding an ellipsis if
  ;; we did.
  (let ((name (bookmark-name-from-full-record bookmark)))
    (cond
     ((= 0 bookmarks-menu-item-length) name)
     ((> (length name) bookmarks-menu-item-length)
      (concat (string-limit name (- bookmarks-menu-item-length 3)) "..."))
     (name))))

;; bookmarks-menu--get-help
(defun bookmarks-menu--get-help (bookmark)
  "Return a :help string for BOOKMARK depending on the bookmark's properties."

  ;; If the bookmark has a `type', prefix the bookmark's name with
  ;; "<type>: ".
  ;; 
  ;; Else, if the bookmark has a custom handler, use the
  ;; name of the handler as the prefix.  Custom handers are commonly
  ;; named "<type>-bookmark-jump", so use only the name up to the first
  ;; "-"; "<Handler>: ".
  ;;
  ;; Else, it is a normal bookmark.  Use its `location'.
  (let ((name (bookmark-name-from-full-record bookmark))
	(type (bookmark-type-from-full-record bookmark))
	(handler (bookmark-get-handler bookmark)))
    (cond
     (type (format "%s: %s" type name))
     (handler (format "%s: %s" (capitalize (car (split-string (symbol-name handler) "-"))) name))
     ((bookmark-location bookmark)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Menu

;; bookmarks-menu--empty
(defun bookmarks-menu--empty ()
  "Remove all items from the Bookmarks menu."

  ;; Traverse the actual menu and remove every item.
  (let ((map (current-global-map)))
    (dolist (bookmark (cdr bookmarks-menu))
      (easy-menu-remove-item
       map bookmarks-menu--path
       (bookmark-name-from-full-record bookmark)))))

;; bookmarks-menu--add-bookmarks
(defun bookmarks-menu--add-bookmarks ()
  "Add bookmarks to the Bookmarks menu."
  ;; Save bookmarks list
  (setq bookmarks-menu--items-list (bookmark-maybe-sort-alist))

  ;; Add bookmarks (before separator)
  (let ((map (current-global-map)))
    (dolist (bookmark bookmarks-menu--items-list)
      ;; `prog' is the command to execute when a bookmark is selected
      ;; from the menu.  The last argument, "--", is the BEFORE
      ;; argument; put each item before the item named "--" that is in
      ;; the same menu.
      (let* ((name (bookmark-name-from-full-record bookmark))
	     (prog `(bookmarks-menu--jump ,name))
	     (help (bookmarks-menu--get-help bookmark)))
	(easy-menu-add-item
	 map bookmarks-menu--path
	 (vector (bookmarks-menu--display-name bookmark) prog :help help)
	 "--")))))

;; bookmarks-menu--add-footer
(defun bookmarks-menu--add-footer ()
  "Add items to the end of the Bookmarks menu."

  ;; If we have bookmarks in the menu, add an "Edit Bookmarks" item at
  ;; the bottom.  Otherwise add "Load Bookmarks" instead.
  ;;
  ;; `menu-bar-bookmark-map' is the "Bookmarks" submenu in the "Edit"
  ;; menu.  Adding it here makes the submenu appear in our menu too,
  ;; but with a different title.
  (let ((map (current-global-map)))
    (if (and (boundp 'bookmark-alist) bookmark-alist)
	(easy-menu-add-item
	 map bookmarks-menu--path
	 (vector "Edit Bookmarks" menu-bar-bookmark-map))
      (easy-menu-add-item
       map bookmarks-menu--path
       (vector "Load Bookmarks" 'bookmarks-menu--load-bookmarks
	       :help (format "Load bookmarks from %s" bookmark-default-file))))))

;; bookmarks-menu--update
(defun bookmarks-menu--update (&optional _symbol _newval _operation _where)
  "Populate the Bookmarks menu.

Any items already in the menu are removed first.  Does nothing if
bookmarks have not changed since the last time the menu was updated, or
if `bookmark-alist' is unbound or nil."

  ;; Don't do anything if there are bookmarks but they have not
  ;; changed.  That should never happen though.  If we're added to the
  ;; menu bar after bookmarks have been loaded, then the bookmarks
  ;; have "changed" from nil.  If we're added to the menu bar before
  ;; bookmarks have been loaded, then `bookmark-alist' is either
  ;; unbound or nil.
  ;; 
  ;; Afterwards, we're only called when `bookmark-alist-modification-count'
  ;; changes, which means the bookmarks have changed.
  (unless (and (boundp 'bookmark-alist)
	       bookmark-alist
	       (equal bookmarks-menu--items-list (bookmark-maybe-sort-alist)))
    (bookmarks-menu--empty)
    (bookmarks-menu--add-bookmarks)
    (bookmarks-menu--add-footer)

    ;; Force recomputation of the menu bar menus (and the frame title,
    ;; and redisplay of all mode lines, tab lines, and header lines).
    (force-mode-line-update t)))

(provide 'bookmarks-menu)

;;; bookmarks-menu.el ends here
