# Vim Elm Help

This plugin allows you to view documentation for any Elm dependencies your project
has, both directly from within Vim as well as offline.

I wrote this plugin at elm-conf because I was working on some Elm code on the plane
on my way to elm-conf, and I didn't like having to view the source of my dependencies
to remember how to use certain functions.  I also don't like viewing reference
documentation in a web browser; I much prefer the offline, in-editor experience that
plugins like manpageview and perlhelp provide when I'm working in C and Perl,
respectively.

Since I wrote this hurriedly at a conference, it was rather hastily put together.  It
works for me, but your mileage may vary.  That being said, I would love it if people
played around with this and helped me out with contributions or comments!

## Usage

### Generate Docs

**IMPORTANT**: You need to do this part while online!  After it's done, you're freeeeeee

Run `bin/build-docs.pl` from the top level of your Elm project, and direct its output
to `elm-docs.json`:

    $ build-docs.pl > elm-docs.json

### Use :ElmHelp

Install `plugin/elm-help.vim` however you like.

If you run the `ElmHelp` command with an argument, the documentation for
that argument will be pulled up in a new window.  For example, `:ElmHelp Keyboard`.

If you don't provide an argument, `ElmHelp` will use whatever word is under the cursor.

# Ideas for improvement

There are many!

  - You need to be online to build the docs themselves, which is less than ideal
  - (related to above) Each module you use has its dependencies fetched, even if you have it in `elm-stuff` already
  - Doesn't generate docs for modules in your current project (this would be easy)
  - Cache docs output for package + version pairs
    - Such a cache would be simple to implement, very effective, and would prevent the need to go online to build the docs
    - Don't cache the current module, though
  - Render markdown as text for docs pane (including transclusion of `@docs`)
  - Make links to other docs followable via `Ctrl-]` in docs pane
  - Tab complete symbols on Vim command line
  - Parse import statements in current buffer to find out what unqualified or alias-qualified identifiers resolve to, keeping in mind which symbols are imported from core by default
  - Hovering over a symbol could automatically show its documentation
  - Showing the docs in a preview window would be nice
  - Using the same window for show docs (instead of opening up a new one for each query) would be a fine alternative to the preview window
  - Offer omnicompletion for imports, exposing, after a dot
  - You could potentially provide gd and gD with this information
