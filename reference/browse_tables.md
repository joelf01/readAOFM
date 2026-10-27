# Print the internal AOFM table index

This is an internal helper used while developing and testing the
package. It prints `x` and returns it invisibly; it does not download
data or query the AOFM website. The public, user-facing catalogue search
is
[`search_aofm()`](https://joelf01.github.io/readAOFM/reference/search_aofm.md).

## Usage

``` r
browse_tables(x = aofm_index_nav)
```

## Arguments

- x:

  An object to print. The default is the package's internal table index
  used to map `security` and `type` arguments to source workbooks.

## Value

`x`, invisibly.
