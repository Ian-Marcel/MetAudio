```
__  __      _                     _ _
|  \/  |    | |     /\            | (_)      Version: v1.0.0-b956a56
| \  / | ___| |_   /  \  _   _  __| |_  ___
| |\/| |/ _ \ __| / /\ \| | | |/ _` | |/ _ \
| |  | |  __/ |_ / ____ \ |_| | (_| | | (_) |
|_|  |_|\___|\__/_/    \_\__,_|\__,_|_|\___/

```

A Bash tool for batch-editing music file tags and reorganizing your music library's folder structure.

Works on `.flac` and `.m4a` files.

---

## What it does, in plain terms

- **Metadata operations** — fix the *tags inside* your music files (artist names, album names, cover art, etc.)
- **Structure operations** — fix *how your files and folders* are named and organized

You pick one type of operation, tell it which folder to work on, and it does the rest.

---

## Install

1. Copy or clone this project anywhere on your computer.
2. Run the script directly:

```bash
./metaudio [OPTIONS] <origin_directory>
```

> [!note]
> If you wish, you can symlink MetAudio somewhere of you're `$PATH` for example:
>
> `$ > sudo ln -s /complete/path/to/metaudio_executable /usr/local/bin/`
>
> MetAudio will handle that. :^)

### Dependencies

The script checks for these automatically and tries to install anything missing:

- `openssl`
- `ffmpeg`
- `metaflac`
- `exiftool`

You don't need to do anything — just make sure you have `apt`, `dnf`, or `pacman` available.

---

## Quick Start

**Fix metadata in a folder:**

```bash
metaudio --metadata-operation=set_album_name /path/to/music
```

**Reorganize folder structure, and copy the results elsewhere instead of moving them:**

```bash
metaudio /path/to/music --structure-operation=artist_base_structure --destination /path/to/output --copy
```

Before anything runs, metaudio shows you what it's about to do and asks:

```
Is info above correct? [Y/n]
```

Add `-y` to skip that and just go.

---

## Learn more

| Topic | Where to look |
|---|---|
| All command-line options (`-m`, `-s`, `-d`, `-c`, etc.) | [docs/options.md](docs/options.md) |
| Metadata operations (fixing tags) | [docs/metadata-operations.md](docs/metadata-operations.md) |
| Structure operations (reorganizing folders) | [docs/structure-operations.md](docs/structure-operations.md) |

You can also always run `metaudio -h` for help, or pass `help` as the value to `-m` or `-s` to see help for that specific operation type.
