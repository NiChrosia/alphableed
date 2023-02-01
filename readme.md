# Alphableed

A simple, pure-nim implementation of alpha bleeding. Credit to urraka for the algorithm used in this, which was taken from [this](https://github.com/urraka/alpha-bleeding) repository.

### usage

```bash
bleed [input] [output]
```

`[input]` must be a valid PNG image file, and output must be a valid file location.

Similarly to the urraka's implementation, a alpha remover (`remove_alpha`) is also provided. Like `bleed`, it takes an input and output with the same constraints.

