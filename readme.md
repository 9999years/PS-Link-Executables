# PS-Link-Executables

Link-Executables is a Powershell script that creates `.bat` files for each file
in a directory or directories matching `$PATHEXT`, so that your `$PATH` doesn’t
grow obscenely large.

It can also make symbolic links instead of `.bat`s, which is basically
unambiguously better (if you have admin privileges!) but also means you can’t
call the folder with all the links “the bat cave,” which unambiguously sucks.

## How to Use It

    $env:PATH.Split(";") | Link-Executables

Don’t actually do that, though; creating `.bat`s linking to, for example, every
program in `Windows/system32` would be very silly indeed. I’ve selected the
directories I want to link and placed them into a `paths.txt` file. Then, I may
simply

    cat ..\paths.txt | Link-Executables

The takeaway here is that it is very simple and easy and good.

## Tell Me More

By creating a `.bat` that looks roughly like

    @"C:\utils\meld\Meld.exe" %*

A shell (or other programs) can find the utilities you need in the path without
having to add dozens and dozens of folders to the path or restart any of your
shells.

Generally, all the `.bat`s are kept in a separate folder, known as the Bat Cave,
which is added to the `$PATH` instead of the dozens of individual folders.

## A Catch

So far, there’s only one large problem: Some programs need to run in the current
directory, and some need to run in their local directory; it can be hard to know
which is which. For example, if the `@cd` line in the above example `.bat` is
included in `git.bat`, anything like `git status` will fail with a cryptic

    fatal: Not a git repository (or any of the parent directories): .git

That’s no good! Usually (I hope) programs need to run in their home directories
to find `.dll`s they depend on — So, if you’re interested, `Link-Executables`
has a `-DLLs` option that will create symbolic links to all the `.dll`s in
supplied directories; this requires administrator permissions and will fail
silently, so make sure you have those!

If you would like to include an `@cd` line in each `.bat`, because that’s useful
to you or whatever, just pass `-CD` to `Link-Executables`. I doubt you need it,
but hey; I’m not the boss of you.
