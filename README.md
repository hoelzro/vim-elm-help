# Vim Elm Help

  - I like offline doc access
  - I like in-editor doc access

## Usage

### Generate Docs

Run `bin/build-docs.pl` from the top level of your Elm project, and direct its output
to `elm-docs.json`:

    $ build-docs.pl > elm-docs.json

### Use :ElmHelp

Install `plugin/elm-help.vim` however you like.

If you run the `ElmHelp` command with an argument, the documentation for
that argument will be pulled up in a new window.  For example, `:ElmHelp Keyboard`.

If you don't provide an argument, `ElmHelp` will use whatever word is under the cursor.

# Todo

  - Privatize the internals of the Vim plugin
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
