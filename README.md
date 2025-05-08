# bookmarks-menu

Add a *Bookmarks* menu to the menu bar.


## Installation

Add either `(buffers-menu-mode t)`, to enable the minor mode, or
`(buffers-menu-add-menu)` to your init file.


## Customization

**Menu Title**

You can change the title of the menu to reduce the amount of space the
menu occupies in the menu bar.  Not surprisingly the default is
`Bookmarks`.

**Menu Placement**

The menu can be placed after any standard menu you choose.

**Jump Target**

This controls where bookmarks will appear when selected from the menu.
The choices are `self`, `window`, and `frame`.  These correspond with
the bookmark commands `boookmark-jump`, `bookmark-jump-other-window`,
and `bookmark-jump-other-frame`.

**Item Length**

By default bookmarks are trimmed to 18 characters in the menu.


## Commands

There are only three commands: `bookmarks-menu-add-menu`,
`bookmarks-menu-remove-menu`, and `bookmarks-menu-mode`.  Enabling and
disabling the minor menu is equivalent to calling the add and remove
menu functions.


## Reasoning

I don't have many bookmarks, and I don't use them much.  I wanted to
add a *Bookmarks* menu, like in web browsers, as a reminder of how
useful Emacs bookmarks can be.  Maybe I'll use them more...

I couldn't find good examples that satisfied my requirements (and
worked).

* Add a top-level menu to the main menu bar
* Specify where the menu is placed
* Dynamically populate the menu when bookmarks are changed

So I've added a lot of comments to the code, hoping to help other
coders build their own menus.  The relevant parts look like this:

```Emacs Lisp
;; Create the menu
(easy-menu-define my-new-menu nil "An awesome new menu" nil)

;; Add the menu to the menu bar
(define-key-after (lookup-key (current-global-map) [menu-bar]) [my-new-menu-key] (cons "New Menu" my-new-menu) 'file)

;; Add items to the menu
(easy-menu-add-item (current-global-map) '("menu-bar" "New Menu") (vector "Scratch Buffer" '(scratch-buffer) :help "Echo area help for item 1"))
(easy-menu-add-item (current-global-map) '("menu-bar" "New Menu") (vector "Delete Other Windows" '(delete-other-windows) :help "Echo area help for item 3"))
(easy-menu-add-item (current-global-map) '("menu-bar" "New Menu") (vector "Split Window Below" '(split-window-below) :help "Echo area help for item 2") "Delete Other Windows")

;; Remove items from the menu
(easy-menu-remove-item (current-global-map) '("menu-bar" "New Menu") "Scratch Buffer")

;; Remove the menu from the menu bar
(define-key (lookup-key (current-global-map) [menu-bar]) [my-new-menu-key] nil t)
```
