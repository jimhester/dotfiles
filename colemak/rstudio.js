// These lines need to be pasted into an open RStudio session in the object inspector
// Right-click anywhere in the source file -> Inspect Element -> Console -> Right-click -> Paste
window.ace.config.loadModule("ace/keyboard/vim", function(m) {
  // rotate some keys about to get qwerty "hjkl" back for movement
  var vim = require("ace/keyboard/vim").CodeMirror.Vim
  vim.mapCommand({keys:"n",type:"motion",motion:"moveByLines",motionArgs:{forward:!0,linewise:!0}})
  vim.mapCommand({keys:"e",type:"motion",motion:"moveByLines",motionArgs:{forward:!1,linewise:!0}})
  vim.mapCommand({keys:"i",type:"motion",motion:"moveByCharacters",motionArgs:{forward:!0}})

  // move these keys to their qwerty positions because they are
  // in the way of hjkl (and E for J)
  vim.mapCommand({keys:"k",type:"motion",motion:"findNext",motionArgs:{forward:!0,toJumplist:!0}})
  vim.mapCommand({keys:"K",type:"motion",motion:"findNext",motionArgs:{forward:!1,toJumplist:!0}})
  vim.mapCommand({keys:"u",type:"action",action:"enterInsertMode",isEdit:!0,actionArgs:{insertAt:"inplace"},context:"normal"})
  vim.mapCommand({keys:"U",type:"action",action:"enterInsertMode",isEdit:!0,actionArgs:{insertAt:"firstNonBlank"},context:"normal"})
  vim.mapCommand({keys:"l",type:"action",action:"undo",context:"normal"})
  vim.mapCommand({keys:"L",type:"operator",operator:"changeCase",operatorArgs:{toLower:!1},context:"visual",isEdit:!0})
  vim.mapCommand({keys:"N",type:"action",action:"joinLines",isEdit:!0})
  vim.mapCommand({keys:"I",type:"motion",motion:"moveToBottomLine",motionArgs:{linewise:!0,toJumplist:!0}})

  // this is the only key that isn't in qwerty or colemak position
  vim.mapCommand({keys:"j",type:"motion",motion:"moveByWords",motionArgs:{forward:!0,wordEnd:!0,inclusive:!0}})
  vim.mapCommand({keys:"J",type:"motion",motion:"moveByWords",motionArgs:{forward:!0,wordEnd:!0,bigWord:!0,inclusive:!0}})

  // Fix key to key mappings that mapped to the old locations
  vim.map('<Right>', 'i')
  vim.map('<Up>', 'e')
  vim.map('<Down>', 'n')
  vim.map('<Space>', 'i')
  vim.map('<C-p>', 'e')
  vim.map('<C-n>', 'n')
  vim.map(';', ':')
})
