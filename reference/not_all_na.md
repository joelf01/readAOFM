# Test whether an object contains at least one non-missing value

This internal predicate is used to drop columns that are entirely `NA`
while parsing transactional workbooks.

## Usage

``` r
not_all_na(x)
```

## Arguments

- x:

  An atomic vector, matrix, or data-frame column to inspect.

## Value

A length-one logical value: `TRUE` when at least one element of `x` is
not `NA`, otherwise `FALSE`.
