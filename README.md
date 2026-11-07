[![GitHub (pre-)release](https://img.shields.io/github/release/szhorvat/MaTeX/all.svg)](https://github.com/szhorvat/MaTeX/releases)
[![Github All Releases](https://img.shields.io/github/downloads/szhorvat/MaTeX/total.svg)](https://github.com/szhorvat/MaTeX/releases)
[![Contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)](https://github.com/szhorvat/MaTeX/issues)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.883841.svg)](https://doi.org/10.5281/zenodo.883841)

----

[English](README.md) | [中文](README.zh_cn.md)

----

# MaTeX

Create LaTeX labels in *Mathematica*.

See [the blog post](http://szhorvat.net/pelican/latex-typesetting-in-mathematica.html) for a detailed introduction to MaTeX and up to date troubleshooting information.

## Installation

**In Mathematica 11.3 or later, simply evaluate `ResourceFunction["MaTeXInstall"][]` to install or upgrade MaTeX.**

In older versions that do not support resource functions, follow the manual installation instructions:

 - [Download the latest release](https://github.com/szhorvat/MaTeX/releases), distributed as a `.paclet` file, and install it using the `PacletInstall` function in Mathematica.  For example, assuming that the file `MaTeX-1.7.10.paclet` was downloaded into the directory `~/Downloads`, evaluate

    ```mma
    Needs["PacletManager`"]
    PacletInstall["~/Downloads/MaTeX-1.7.10.paclet"]
    ```

    The most convenient way to obtain the path to a file is Mathematica's Insert → File Path... menu command.

 - Make sure that [a TeX system](https://tug.org/begin.html) and Ghostscript 9.15 or later are installed.  

     For Windows and Linux, the latest Ghostscript is available from [its official download page](http://ghostscript.com/download/gsdnld.html).  

     On OS X, MacTeX 2015 and later already include a compatible version of Ghostscript. If you use an older TeX distribution that doesn't, please obtain a recent Ghostscript from [Richard Koch's page](http://pages.uoregon.edu/koch/).

 - Evaluate ``<<MaTeX` ``.  MaTeX will attempt to auto-configure itself when it is loaded for the first time.  If auto-configuration fails, it will display instructions on how to configure the path to the `pdflatex` and Ghostscript executables manually.  *Note:* On Windows systems use the command line Ghostscript executable, i.e. the one with the name ending in c: `gswin32c.exe` or `gswin64c.exe`.

 - Test MaTeX using `MaTeX["x^2"]`.

    Open the documentation center and search for "MaTeX" to get started.

## Upgrading or uninstalling

A newer version can be safely installed when an older version is already present.  ``<<MaTeX` `` will always load the latest installed MaTeX that is compatible with your version of Mathematica.

A list of all installed versions can be retrieved using

```mma
PacletFind["MaTeX"]
```

Any of the items in the list can be uninstalled by applying `PacletUninstall` to it.  To uninstall all versions at once, use

```mma
PacletUninstall["MaTeX"]
```

To see more information about the version that gets loaded by `Needs`, use

```mma
PacletInformaton["MaTeX"]
```

**Note:** If you installed MaTeX before it started using the paclet distribution format (i.e. version 1.6.2), uninstall it by removing the `MaTeX` directory from the following location:

```mma
SystemOpen@FileNameJoin[{$UserBaseDirectory, "Applications"}]
```

----

The following function will automatically download the latest release of MaTeX and install it:

```mma
updateMaTeX[] :=
  Module[{json, download, target},
    Check[
      json = Import["https://api.github.com/repos/szhorvat/MaTeX/releases/latest", "JSON"];
      download = Lookup[First@Lookup[json, "assets"], "browser_download_url"];
      target = FileNameJoin[{CreateDirectory[], "MaTeX.paclet"}];
      If[$Notebooks,
        PrintTemporary@Labeled[ProgressIndicator[Appearance -> "Necklace"], "Downloading...", Right],
        Print["Downloading..."]
      ];
      URLSave[download, target]
      ,
      Return[$Failed]
    ];
    If[FileExistsQ[target], PacletManager`PacletInstall[target], $Failed]
  ]
```

After evaluating the function definition above, just run `updateMaTeX[]`, then ``<<MaTeX` `` to load the updated version.


## Usage

### Raw LaTeX notebook cells (local addition)

Load the optional notebook helper from this checkout:

```mma
Get["/home/rdkgsk/Projects/MaTeX/MaTeX/Notebook.m"];
MaTeX`Notebook`CreateLaTeXNotebook[]
```

Choose **LaTeX** from the cell style menu and write a LaTeX note in text mode,
with single backslashes and no surrounding Wolfram string quotes. Use `$...$`
for inline math and `\[...\]` or `equation` for display math. Blank lines create
paragraphs; commands such as `\textbf` and environments such as `itemize` work.
Press **Shift+Enter** to render an ordinary graphic output beneath the source.
The source editor uses the notebook's Text cell font, size and weight.
The helper wraps each note in a 15 cm wide text paragraph box, so lines wrap.
Supply document-body content, without `\documentclass`, `\usepackage`, or
`\begin{document}`. Each cell compiles independently, so equation counters and
cross-references do not span cells. Page floats such as `figure` are not supported
inside the paragraph box. MaTeX's default packages (including amsmath) are loaded.
Existing math-only cells now need math delimiters when re-rendered; for example,
change `\frac{1}{2}` to `$\frac{1}{2}$`.
Ordinary typed or pasted text is accepted even if Mathematica internally stores
the cell in `BoxData`/`RowBox` form. The evaluator reads the stored source cell
directly, preserving spaces that Mathematica may strip from evaluation input.
LaTeX itself still applies its normal whitespace rules (multiple spaces collapse
to one, and blank lines start paragraphs). Typeset fractions and other two-dimensional
notation must be replaced with their raw LaTeX source. After updating this file,
reload it with `Get` and rerun `EnableLaTeXCells` to refresh a notebook's embedded
evaluator.

For an existing notebook, evaluate
``MaTeX`Notebook`EnableLaTeXCells[EvaluationNotebook[]]``. Alternatively, run
``MaTeX`Notebook`InsertLaTeXCell[]`` to enable the style and insert a source cell
at the selection in the input notebook. The helper adds this checkout to the
current kernel's search path; it does not install a paclet.

The source, ordinary output graphics, and embedded stylesheet are saved in the
`.nb`. Another Mathematica installation can display saved output and edit the
source without this helper or MaTeX. Re-rendering requires MaTeX, TeX and
Ghostscript. Editing source does not update its output until evaluated. Do not
delete output cells before saving if you want the rendered equations to travel
with the notebook. The source/output group can be collapsed using Mathematica's
normal cell grouping controls.

`examples/LaTeXCells.nb` is a starter notebook with the style already embedded.
It initially contains source only; load MaTeX in the kernel (or load the helper
above) and evaluate the example to render it. In a normal installed MaTeX setup,
the embedded evaluator loads MaTeX automatically when first used.

Run structural and serialization checks with
`WolframKernel -noinit -noprompt -script tests/Notebook.wls`.
These also compile a mixed text/math note with `pdflatex` and inspect it with
`pdftotext`. They do not verify front-end keyboard dispatch or PDF import.

Use `MaTeX[texcode]` or `MaTeX[expression]` to typeset using LaTeX.  The latter will automatically apply `TeXForm` to `expression`.

The LaTeX code is interpreted in math mode.  Remember to escape backlashes (i.e. type *two* `\` characters when you mean one) when writing LaTeX code in Mathematica strings, e.g.

```mma
MaTeX["\\sum_{k=1}^{\\infty} \\frac{1}{k}"]
```

Multiple expressions can also be processed in one go:

```mma
MaTeX[{
  "\\frac{x^2}{\\sqrt{3}}",
  HoldForm[Integrate[Sin[x], {x, 0, 2 Pi}]],
  Expand[(1 + x)^5]
}]
```

Processing a list of expressions together involves a single run of LaTeX, thus is much faster than processing each separately.

For many usage instructions, search for "MaTeX" in the documentation center.

## Notes on performance

The limiting factor in the speed of `MaTeX` calls is running the `pdflatex` process, which might take as long as a second and cannot be sped up further.  However, MaTeX caches results, making subsequent calls with the same TeX code near-instantaneous.  MaTeX can also process a list of expressions using a single run of LaTeX, which is much faster than processing each separately.

## Revision history

#### Version 1.7.10

 - Compatibility with Ghostscript 10.03.0 and later

#### Version 1.7.9

 - Invalid entries in the system `PATH` no longer cause MaTeX to issue messages with Mathematica 13.1 and later

#### Version 1.7.8

 - Improve compatibility with future Mathematica versions

#### Version 1.7.7

 - Fix compatibility with Ghostscript 9.53.1

#### Version 1.7.6

 - Improved compatibility with Mathematica 12.0 and 12.1
 - Reliability improvements

#### Version 1.7.5

 - Documentation improvements
 - Improved error reporting

#### Version 1.7.4

 - Documentation improvements

#### Version 1.7.3

 - Added `"WorkingDirectory"` configuration option. This allows users to work around a `RunProcess` bug in some Mathematica versions on Windows where `RunProcess` would fail in a directory with non-ASCII characters in its name.
 - Exposed ``MaTeX`Developer`Texify``, to allow users to customize the expression to TeX code conversion. See Neat Examples in the MaTeX symbol documentation page.
 - Documentation improvements

#### Version 1.7.2

 - Better compatibility with the new documentation search in Mathematica 11.2
 - Better error reporting in case of Ghostscript failure
 - Documentation improvements

#### Version 1.7.1

 - Work around a rare `RunProcess` bug that affects some Mathematica 10.0 installations on Linux
 - Documentation improvements, along with a new tutorial on figure preparation

#### Version 1.7.0

 - Internal refactoring, minor bug fixes and polish
 - New functions in ``MaTeX`Developer` `` to aid troubleshooting
 - Bug fix: running Ghostscript or pdflatex would fail on certain Linux distributions due to Mathematica changing `LD_LIBRARY_PATH`

#### Version 1.6.3

 - More robust error checking and reporting
 - Documentation improvements

#### Version 1.6.2

 - The documentation is now integrated into the Documentation Center.
 - Bug fix: full compatibility with Mathematica 10.0 restored.

#### Version 1.6.1

 - Bug fix: better error checking for the CacheSize configuration option.

#### Version 1.6.0

 - `MaTeX` now threads over lists. A list is batch-processed using a single run of LaTeX, which is much faster than element-wise processing. Implemented by [Andreas Ahlrichs](https://github.com/aquadr).

    Note that this changes behaviour slightly.  Previous versions of MaTeX compiled `MaTeX[{1, x^2, x/2}]` as a single expression.  Now each element of the list is converted to a separate result.  To restore the old behaviour, apply `TeXForm` explicitly: `MaTeX[TeXForm[{1, x^2, x/2}]`.

 - Expressions with head `TeXForm` are now automatically handled.

 - Bug fixes: Better handling of CR/LF line endings and character encodings.

#### Version 1.5.0

 - Much improved LaTeX error reporting. Please report any problems you notice with the new error reporting.
 - MaTeX now checks for common user errors and issues warnings.  Turn them off using `Off[MaTeX::warn]`.

#### Version 1.4.0

 - Separated `"Preamble"` and `"BasePreamble"` options.  The default preamble is now in `"BasePreamble"`.  The `"Preamble"` option can be set without needing to worry about the default.
 - Package symbols are protected
 - MaTeX now follows the standard Mathematica package structure.  This means that it now consists of multiple files.  Move the entire MaTeX directory (and not just `MaTeX.m`) into `$UserBaseDirectory/Applications` to install.

#### Version 1.3.0

 - Added the `"TeXFileFunction"` and `"LogFileFunction"` options for easier debugging.  Set them to `Print` to see the generated LaTeX code or the LaTeX log file.

#### Version 1.2.0

 - Added `ContentPadding` option: `ContentPadding -> True` ensures that the the output height is at least one line height
 - Added `LineSpacing` option
 - The size of vertical borders is slightly different now: use `LineSpacing -> {0, 14.4}` to reproduce the older behaviour
 - Bug fixes

#### Version 1.1.1

 - Reliability fixes for Windows
 - Windows: Work around Mathematica bug causing MaTeX to fail when the current directory has special characters in its name
 - Windows: Ensure that auto-detected paths do not use `/` as path separator

#### Version 1.1.0

 - MaTeX now attempts to automatically detect the location of Ghostscript and pdflatex on first run
 - Syntax highlighting for MaTeX functions (added SyntaxInformation)
 - Minor bug fixes and reliability fixes

#### Version 1.0.0

 - Minor bug fixes and compatibility fixes

#### Version 0.3

 - Bug fixes and other compatibility fixes: works with XeTeX and behaves better on Windows.  

#### Version 0.2

 - Automatic baseline alignment.  MaTeX output is now perfectly aligned with Mathematica text.
 - Improved positioning accuracy
 - Added `FontSize` option (now requires the `lmodern` package)
 - Support for some accented characters
 - More robust `Magnification` handling

#### Version 0.1

 - Initial release

## Feedback

MaTeX was primarily created for my own needs.  However, if you find it useful, feel free to drop me an email.

Send feedback or bug reports to `szhorvat` at `gmail.com` or [open an issue in the tracker](https://github.com/szhorvat/MaTeX/issues).
