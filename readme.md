# Alphableed

A simple, pure-nim implementation of alpha bleeding. Credit to urraka for the algorithm used in this, which was taken from [this](https://github.com/urraka/alpha-bleeding) repository.

### Installation

Assuming you have [Nim](https://nim-lang.org) installed, simply run `nimble install`.

### Usage

```bash
bleedalpha [input] [output]
```

`[input]` must be a valid PNG image file, and output must be a valid file location.

Similarly to the urraka's implementation, a alpha remover (`rmalpha`) is also provided. Like `bleedalpha`, it takes an input and output with the same constraints.

