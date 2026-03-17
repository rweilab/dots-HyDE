Was going to be a <del>GNU STOW</del> system but unfortunately Stow works better as a *symlink manager* and not as a pack-up-and-go environment. Maybe one day I'll learn NixOS.

To be used after installing **Project HyDE** which changes directory structures.

Also used with:
- <del>Oh My Zsh!</del>
- DOOM Emacs
- <del>LazyVim</del>

for easy setup of sensible defaults which also *change folder structure*.

Notes to future self:
about:config
    toolkit.legacyUserProfileCustomizations.stylesheets -> True
    ui.key.menuAccessKeyFocuses -> False
about:support
    chrome/userChrome.css needs to be created with:
```
#TabsToolbar {
	visibility: collapse !important;
}

/* Remove extra spacers next to the tab bar for cleaner layout */
.titlebar-spacer[type="pre-labs"],
.titlebar-spacer[type="post-tabs"] {
	display: none ~important;
}
```

Sidebery's configurations can be exported/imported with JSON.
