# Chezmoi Files
This was going to be a <del>GNU STOW</del> system but unfortunately Stow works better as a *symlink manager* and not as a pack-up-and-go environment. Maybe one day I'll learn NixOS.

## Note:
To be used after installing **Project HyDE** which changes directory structures.

Also used with:
- DOOM Emacs
for easy setup of sensible defaults which also *change folder structures*.

## Notes to future self:  
- about:config changes
> toolkit.legacyUserProfileCustomizations.stylesheets -> True  
> ui.key.menuAccessKeyFocuses -> False  

- about:support 
> chrome/userChrome.css needs to be created with:  

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

- Sidebery's configurations can be exported/imported to JSON.

- Waybar can be selected through Rofi using `hyde-shell waybar -S`

```
Hyprlock sourcing is weird with HyDE. The layout is defined by ~/.config/hypr/hyprlock/HyDE.conf
whose layout is defined by: ~/.config/hypr/hyprlock/HyDE.conf
which sources $BACKGROUND_PATH from ~/.local/share/hypr/hyprlock.conf
which is defined as $XDG_CACHE_HOME/hyde/wall.set.png

I've elected to use chezmoi to maintain wall.set.png
```
 
