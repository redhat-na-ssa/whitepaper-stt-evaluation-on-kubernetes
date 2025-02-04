# Example using pandoc

[Example Document](EXAMPLE.md)

```sh
pandoc \
  --from=markdown \
  --output=example.pdf EXAMPLE.md \
  --variable=geometry:"margin=0.5cm, paperheight=421pt, paperwidth=595pt" \
  --highlight-style=espresso
```

## Reference

- https://tex.stackexchange.com/questions/101717/converting-markdown-to-latex-in-latex#246871
