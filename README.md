Filename Changer
================

Changing filenames is so laboring in Bash. Don't you sometimes just want to
open your favorite powerful editor (*read: VIM*) on the list of filenames
in the current directory and do whatever change you want and in the end the filenames
will just magically change as you wish?

Well you are in luck. `fnc` does just that. It opens up your editor ($EDITOR),
lets you edit the list of filenames (including directories), calculates changes,
and convert those changes into system calls.
