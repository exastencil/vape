# Vape (is a Work in Progress)

The functional web micro-framework!

[![time tracker](https://wakatime.com/badge/github/exastencil/vape.svg)](https://wakatime.com/badge/github/exastencil/vape)

## About

### What does it do?

It helps you structure your code into units that handle HTTP web requests.
Each of these are called **handlers**. They can then be compiled and deployed
individually, or linked to a router and deployed together.

### Why would you want to do that?

This structure opens up some opportunities. Individual **handlers** can run in
their own lambda function or similar serverless environment. You can have quick
deploys of individual **handlers** or do checksum diffing to deploy only ones
that have changed. In more advanced cases you could group **handlers** together
and scale groups vertically or horizontally to accommodate your traffic.

### Okay, but that leaves a lot for me to do.

That is not a question, but yes. Vape will try to bring all the tools together
to help you route handlers, develop locally and compile **handlers** in the
configuration of your choosing.

## Getting Started

### Install V

You'll need `v` available globally so follow the instructions
[here](https://github.com/vlang/v#installing-v-from-source).
```
git clone https://github.com/vlang/v
cd v
make
sudo ./v symlink
```

### Install Vape

Vape is packaged as a V module for now, so you can install it with:

```
v install exastencil.vape
```

This will clone the repository into `~/.vmodules/exastencil/vape`.

This repository contains library code needed to compile Vape apps and a command
line utility to help you build and run them.

### Install the CLI

First you need to build it:

```
v ~/.vmodules/exastencil/vape/commands/vape.v
```

This will build the executable at `~/.vmodules/exastencil/vape/commands/vape`.

I'd recommend moving it onto your path with something like:

```
mv ~/.vmodules/exastencil/vape/commands/vape /usr/local/bin
```

where `/usr/local/bin` could be anywhere on your path.

To test that the CLI is working try `vape` and it should output help.

### Start a project

To start a new project simply create an empty folder and execute `vape init`
within it.

This sets up a basic file structure and a sample handler to get you started.

Add as many endpoints as you need. `endpoints/hello.v` should have been provided
as an example.

To run the all endpoints in a web server in your local environment run
`vape dev` in the root of your project.

```
➜ vape dev
🔪 Dissecting handlers…
   ↜ endpoints/hello.v

🧠 Compiling development server…
🚀 Launching development server on port 6789… Ctrl + C to exit.

```

Visit [http://localhost:6789/hello](http://localhost:6789/hello) to see it in
action.

## Planned Features

- Dynamic routing for local development
- Named route parameters and query parameters
- Host context
- Standardized logging
- Built-in benchmarking
- Hot code reloading for local development
- Individual endpoint compilation
- Build checksums

And some longer term, bigger picture features…

- Deployment helper as in `vape deploy`
- Entity persistence
- Scheduled handlers (cron-like handlers)
- Messaging handlers (e.g. email)

## Author

- [Exa Stencil](https://github/exastencil)

## Acknowledgements

Vape is made possible by the [V language](https://vlang.io). Where possible it
relies on its standard library, and even where it isn't it is usually used as
a reasonable starting point.

Vape is a side-project to which very little time is dedicated. The best way to
support Vape is to support V.
