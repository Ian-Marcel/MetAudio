# Command-Line Options

```
metaudio [OPTIONS] <origin_directory>
```

| Option | Description |
|---|---|
| `-m=<op1,op2,...>`, `--metadata-operation=<op1,op2,...>` | Comma-separated list of metadata operations to run. Conflicts with `-s`/`--structure-operation`. |
| `-s=<op1,op2,...>`, `--structure-operation=<op1,op2,...>` | Comma-separated list of structure operations to run. Conflicts with `-m`/`--metadata-operation`. |
| `-d <directory>`, `--destination <directory>` | Directory to send output files to. Defaults to move behavior unless `-c`/`--copy` is specified. The transport flag must be declared either before `-d` or after the destination path. |
| `-m`, `--move` | Move files to the destination directory (default transport method when `-d` is used). |
| `-c`, `--copy` | Copy files to the destination directory instead of moving them. |
| `-y`, `--assume-yes` | Skip the confirmation prompt and proceed automatically. |
| `-h`, `--help` | Show the help message. |

## Good to know

- You **can't** use `--metadata-operation` and `--structure-operation` at the same time — pick one.
- `<origin_directory>` can go anywhere in the command — before, after, or between other options.
- If you don't pass `--destination`, files are edited in place.
- Passing `help` as the value of `-m` or `-s` prints help for that operation type and exits (e.g. `metaudio -m=help`).

## Examples

```bash
metaudio --metadata-operation=opt1,opt2 <origin_directory>
metaudio <origin_directory> --structure-operation=opt1,opt2 --destination <destination_directory>
metaudio -d <destination_directory> <origin_directory> -m=opt1,opt2
metaudio <origin_directory> -s=opt1,opt2
```

## Confirmation prompt

Unless you pass `-y`/`--assume-yes`, metaudio shows you the resolved origin (and destination/transport method, if set) and asks:

```
Is info above correct? [Y/n]
```

---
[← Back to README](../README.md)
