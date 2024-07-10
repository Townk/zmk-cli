# ZMK CLI tool set

The ZMK CLI is a collection of scripts that help one to build a ZMK firmware
from inside a user-configuration project, without having to worry about a
secondary ZMK repository, nor the Zephyr SDK.

## Motivation

The reason I created the ZMK CLI, was to address a frustration of mine.
Whenever I was modifying my configuration to test a new keyboard layout, or
fixing something I found weird on an old one, I would have to jump between the
ZMK repository and my user configuration all the time.

Moreover, whatever I did to build my config, I would have to replicate on the
`build.yaml` file if I wanted to have the GitHub action to be able to build the
config for me.

It was very common for me to have my firmware building just fine locally, and
have the GitHub action failing for weeks before I noticed any problem.

To complicate things even more, whenever I tried to search for documentation
about how to build the firmware from inside my config repository, I would find
not much information, or something on the lines of “you have to do the same
that the GitHub action is doing”.

All these experiences made me wonder how I could connect both worlds to declare
what I wanted to build once, and be able to build the same thing locally and in
the GitHub action. And from there, ZMK CLI was born.

## Goals

This project is not intended to be a fancy builder for ZMK, nor is trying to
replace “West” from the Zephyr project. It is simply a collection of helper
scripts that “automate” tasks that most ZMK configuration projects have to
perform when building their firmware locally.

One of the biggest desires I have for this project is to not _hide_ what is
being done when bootstrapping, building, or flashing a firmware. A user will be
able to pass an optional flag to every command, and have the script printing
the exact command being executed during these operations.

## Getting Started

If you got interested in this project, there are two ways you can start playing
with it today:

1. Copying the files in the `bin` directory of this repository to some place on
   your computer that is added to the `PATH` variable;
2. Using Nix Flakes to create a development environment for your project;

The first option is pretty straightforward and does not require any
explanation. If you're building a ZMK firmware locally, you should know what to
do in this case.

The second option is the preferred option for those, like me, that use Nix as
their system configuration driver.

Simply go to your user configuration directory and run:

```sh
git init # if, for some reason, you're not using Git in your config
nix flake init --template github:Townk/zmk-cli
git add .
nix develop
zmk bootstrap
```

This will make Nix download all the dependencies to build your firmware, and
put you in a shell with the ZMK CLI in your path, ready to be used.
