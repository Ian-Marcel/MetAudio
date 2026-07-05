# MetAudio

A Bash command-line tool for batch-editing audio file metadata and reorganizing music library folder structures. It operates on `.flac` and `.m4a` files (per the `EXTENSIONS` variable in the main script, which also has a comment noting `mp3 ogg opus wma` as a possible future addition).

## Dependencies

Checked automatically at runtime by `lib/check-dependencies.sh`, which attempts to install any that are missing via `apt`, `dnf`, or `pacman`:

- `ffmpeg`
- `metaflac` (from the `flac` package)
- `exiftool`

## Installation

Clone or copy this project to a local directory, then run the `metaudio` script directly (it resolves its own script directory at runtime, so it can be invoked from anywhere):

```bash
./metaudio [OPTIONS] <origin_directory>
```

[Inference] Making the script executable (`chmod +x metaudio`) or placing it on your `PATH` would likely be needed for convenient use, though this is not stated in the project files themselves.

## Usage

```
metaudio [OPTIONS] <origin_directory>
```

### Options

| Option | Description |
|---|---|
| `-m=<op1,op2,...>`, `--metadata-operation=<op1,op2,...>` | Comma-separated list of metadata operations to run. Conflicts with `-s`/`--structure-operation`. |
| `-s=<op1,op2,...>`, `--structure-operation=<op1,op2,...>` | Comma-separated list of structure operations to run. Conflicts with `-m`/`--metadata-operation`. |
| `-d <directory>`, `--destination <directory>` | Directory to send output files to. Defaults to move behavior unless `-c`/`--copy` is specified. The transport flag must be declared either before `-d` or after the destination path. |
| `-m`, `--move` | Move files to the destination directory (default transport method when `-d` is used). |
| `-c`, `--copy` | Copy files to the destination directory instead of moving them. |
| `-y`, `--assume-yes` | Skip the confirmation prompt and proceed automatically. |
| `-h`, `--help` | Show the help message. |

Notes (from `docs/help.txt`):

- `--metadata-operation` and `--structure-operation` cannot be used together.
- `<origin_directory>` can be declared at any position in the argument list.
- If `--destination` is not declared, files are processed in place.

### Examples

```bash
metaudio --metadata-operation=opt1,opt2 <origin_directory>
metaudio <origin_directory> --structure-operation=opt1,opt2 --destination <destination_directory>
metaudio -d <destination_directory> <origin_directory> -m=opt1,opt2
metaudio <origin_directory> -s=opt1,opt2
```

Passing `help` as the value of `-m`/`--metadata-operation` or `-s`/`--structure-operation` prints the corresponding operation-specific help text and exits.

## Metadata Operations (`-m`/`--metadata-operation`)

| Operation | Description |
|---|---|
| `multiple_artists` | FLAC only. Splits a single `ARTIST` tag containing multiple artists (comma- or "feat."-separated) into a primary `ARTIST` entry plus separate `ARTISTS` entries for contributing artists, and sets the first artist as `ALBUMARTIST`. Intended for Navidrome compatibility. |
| `set_album_name` | Sets the `ALBUM` tag using the existing `TITLE` tag value, on files where `ALBUM` is missing. Has no effect on files that already have `ALBUM` set. |
| `trim_artwork` | Trims embedded cover art with a disproportionate aspect ratio down to 1:1 by center-cropping. Skips artwork that is already 1:1. |
| `set_album_artist` | Surveys the `AlbumArtist` tag across all tracks in each album folder. If it's missing or present in a minority of tracks, falls back to `Artist`/`Artists` tags (splitting comma/"feat."-delimited values before counting; for FLAC files already processed by `multiple_artists`, existing `ARTISTS` tags are read directly). The most frequently occurring value is written as `AlbumArtist` on every track in the album. |

## Structure Operations (`-s`/`--structure-operation`)

| Operation | Description |
|---|---|
| `track_positioner` | Reads the track number from each file's metadata and prepends it to the filename (e.g. `3 - Song Title.flac`). Skips files that are already numbered, and warns/skips files with no retrievable track number. |
| `sort_album_type` | Prepends a type prefix to each album folder's name based on track count: `Single -` (1–2 tracks), `Extended Play -` (3–7 tracks), or `Full Length -` (8+ tracks). Skips folders already classified, and strips any pre-existing non-classification prefix (e.g. a leading year) first. |
| `artist_base_structure` | Reads the `AlbumArtist` tag from the first track of each album folder and moves the album under an `Artist/Album` structure inside the origin directory. Skips albums whose first track has no `AlbumArtist` tag, and skips (with a warning) if the destination path already exists. |

Both operation types accept `help` as the option value to print their dedicated help file (`docs/metadata_ops-help.txt` or `docs/structure_ops-help.txt`).

## Confirmation Prompt

Before executing (unless `-y`/`--assume-yes` is passed), the script prints the resolved `ORIGIN` (and `DESTINATION`/transport method, if set) and asks `Is info above correct? [Y/n]` before proceeding.
