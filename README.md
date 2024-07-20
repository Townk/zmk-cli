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

### Why use Bash instead of some cool language, or a build framework?

I looked into several possibilities when I decided I wanted to automate my
local build process. Between most solutions I looked into (from using things
like GNU Make, Just, or something similar, to the 'West' build itself) there
was one common thing: The chosen solution would inevitably use some Shell
commands to perform its work.

When that was clear to me, I decided that it would be better to cut off the
middleware between the Shell commands I would need and the ZMK CLI, and use
Bash directly.

I wanted to use ZSH instead of Bash for this project, but unfortunately, Bash
is more predominant on every Unix-like system, and besides that, even when a
system uses ZSH as the main shell, it usually has Bash installed.

## Goals

This project is not intended to be a fancy builder for ZMK, nor is trying to
replace “West” from the Zephyr project. It is simply a collection of helper
scripts that “automate” tasks that most ZMK configuration projects have to
perform when building their firmware locally.

One of the biggest desires I have for this project is to not _hide_ what is
being done when bootstrapping, building, or flashing a firmware. A user will be
able to pass an optional flag to every command, and have the script printing
the exact command being executed during these operations.

## Dependencies

I tried my best to minimize any “extra software” installation required to run
the ZMK CLI, but there are some requirements that anyone trying to use this
project won't be able to not install them.

Before trying to run the ZMK CLI, make sure your system has all the following
requirements.

For the ZMK firmware build, you should follow the ZMK documentation about
building locally, that will give you the following:

- A fully functional ZMK Build Tool. This means that you'll have to have a
  cross-platform compiler (on Nix, I use `gcc-arm-embedded`), CMake, Ninja, and
  Python3;
- The `west` build tool and its required Python libraries;

The ZMK CLI itself depends on several tools from GNU Core Utils (`sed`, `tr`,
`fmt`, `uname`), and these basic terminal utilities:

- `tar`;
- `curl`;

Usually, on Linux systems, these tools are installed by default, but
double-check to make sure the CLI runs smoothly.

Besides these tools, the CLI scripts use 2 external applications that are not
guaranteed to be installed on every system:

- `fzf`;
- `yq`;

`fzf` is a well-known utility, and I decided to let the user decide how to
install it. `yq`, in the other hand, it's not that mainstream, so the ZMK CLI
will try to download the portable binary of the tool if it is not installed on
your system.

## Getting Started

If you got interested in this project, there are two ways you can start playing
with it today:

1. Copying the files in the `bin` directory of this repository to some place on
   your computer that is added to the `PATH` variable;
2. Using Nix Flakes to create a development environment for your project;

The first option is pretty straightforward and does not require detailed
explanation. If you're building a ZMK firmware locally, you should know what to
do in this case, but the following is a suggestion of steps to follow:

```sh
mkdir -p ~/.local/{opt,bin}
git clone https://github.com/Townk/zmk-cli.git ~/.local/opt/zmk-cli
ln -sf ~/.local/opt/zmk-cli/bin/* ~/.local/bin/
export PATH="~/.local/bin:$PATH" # put this line in your .bashrc or .zshrc
```

After the scripts are added to the `PATH` environment variable, go to your
configuration directory and bootstrap the build system with the CLI:

```sh
zmk bootstrap
```

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

After your configuration is _“bootstrapped”_, you can use the `zmk build`, and
`zmk flash` commands.
