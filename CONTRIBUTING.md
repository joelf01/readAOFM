# Contributing to readAOFM

Contributions that improve reproducibility, documentation, or
compatibility with the Australian Office of Financial Management (AOFM)
Data Hub are welcome. Please use the [issue
tracker](https://github.com/joelf01/readAOFM/issues) for discussion
before substantial changes.

## Issues

For a bug or changed workbook layout, include the readAOFM version or
commit, R version, operating system, table selector, access date, a
minimal reproducible example, and the expected and actual result. Remove
credentials, tokens, private data, and unnecessary downloaded workbooks
before posting. Use the security guidance in
[SECURITY.md](https://joelf01.github.io/readAOFM/SECURITY.md) for
sensitive reports.

## Pull requests

Keep changes focused and preserve the public function signatures, return
contracts, source attribution, and offline testability. Add or update
tests and user documentation when behaviour or supported source layouts
change. Do not commit downloaded AOFM workbooks, generated
check/tarball/site output, or credentials. A useful local baseline is:

``` sh
R CMD check .
```

If a change depends on a live AOFM response, include a deterministic
fixture or mock for the test path and explain the source URL and
licensing terms. Pull requests should describe compatibility
considerations and any check results that were actually run.
