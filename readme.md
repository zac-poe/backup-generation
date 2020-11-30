# About
This repo contains a simple script for generating archives from a provided list of target files.

# Targets File
A targets file is simply a text file containing a list of files (or directories).

A targets file must contain a single filename per line. File names must be fully qualified with paths.

Blank lines or lines beginning with a `#` character will be ignored.

# Usage
Usage requires the `-t` option along with your targets file. (Relative paths for target files are supported.)

Unless otherwise specified with the `-d` option, backups will be generated at the same location as the provided targets file.

The `-m` option may be provided with the maximum number of backups to retain.

Invoke `./backup.sh -h` or `./backup.sh help` for a full list of supported options.
