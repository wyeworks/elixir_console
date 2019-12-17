[![Build Status](https://travis-ci.org/wyeworks/elixir_console.svg?branch=master)](https://travis-ci.org/wyeworks/elixir_console)
[![SourceLevel](https://app.sourcelevel.io/github/wyeworks/elixir_console.svg)](https://app.sourcelevel.io/github/wyeworks/elixir_console)

---

# Elixir Web Console

The [Elixir Web Console](https://elixirconsole.wyeworks.com/) is a virtual place where people can try the [Elixir language](https://elixir-lang.org/ Elixir language) without the need to leave the browser or installing it in their computers. While this is still a project in its early stages, we hope this is a contribution to promote the language, bringing a confortable to developers to discover the wonders of this technology. We recognize that more work has to be done to fulfill this goal, and for this reason, we would love to hear ideas about how to extend this project to better serve to this purpose (see the Contributing section).

This is inspired in existing playground sites for other technologies, such as [SwiftPlayground](http://online.swiftplayground.run/) and [Rust Playground](https://play.rust-lang.org/), but this is somehow different because it aims to mimic the [Elixir interactive shell (iEX)](https://hexdocs.pm/iex/IEx.html) providing a more interactive user experience.

# Features

  * Binding are persisted through the current session. Users can assign values to variables and their are always visible at the side of the screen.
  * Autocomplete can be triggered pressing the Tab key. It will help to discover module's public functions and already defined bindings.
  * Commands history is visible to the user, including links to display the documentation of Elixir functions that were used. 
  * Easy access to already-executed commands pressing Up and Down keys.

![Elixir Web Console](https://media.giphy.com/media/JUM6QQWQWjDpA03MBv/giphy.gif "Elixir Web Console")

# Where my Elixir code is executed?

Unlike other playground projects, user code is executed into the Elixir application that is serving the web page. It does not rely on spawing sandbox nodes or servers that are responsible to run the code. Of course, there are plenty of security considerations related with the execution of code from not-trusted sources, but we are dealing with that directly on our Elixir backend code (see next section). 

Each sumbitted command is run in the context of a process that is used thought the whole session. It means that subsequent calls to `self()` should return the same pid value. At the same time, this process is only used to run user code, so there is no risk to have conflict with the LiveView channel process or other processes in the system.

# How much Elixir can I run in the web console?

As you might guess, not all Elixir code is safe to be run in our online console. The system verifies is the provided code is safe enough to be executed before attempting to do it. It relies on the capability of Elixir to return the AST of a provided piece of code, so it is relativelity easy to inspect it before running the code.

## Elixir safe modules and Kernel functions

The console has a whitelist of allowed Elixir's modules and safe `Kernel` functions. If users attempts to use dangerous modules, an error is returned. We are limiting the modules having access to the filesystem, the networks, the system itself (ErlangVM and server operating system). In addition, Elixir metaprogramming modules and functions are also forbidden.

The function `Kernel.apply` is also not available, in order to avoid the indirect invokation of not-secure functions.

## Processes

Currently, we have limited the `Process` module and additional modules and functions that can create additional processes. Existing resource usage limitations (see next section) would be much harder to enforce if users were able to spawn processes. Also, `send` and `receive` functions are not available to avoid integrity and security issues.

This is a limitation that **does not make us happy**, since processes are a very interesting aspect of Elixir to play with in an interactive shell. We have ideas to make possible the usage of processes in a controlled manner although it has to be done with some caution due to additional security implications.

## The problem with atoms

It represents a tricky issue for our web console, because in Elixir/Erlang atoms are never garbage collected. Therefore, each atom created by users code will be added to the global list of existing atoms. It means that, eventually, the [maximum number of atoms](http://erlang.org/doc/efficiency_guide/advanced.html#atoms) will be reached, making the server crash.

We are considering this issue as not severe, at least for now. The website is deployed in Heroku and it will automatically restart if that happens. Of course, existing session will be lost and it is not acceptable if it happens often, but we are currently monitoring the server in order to learn how to better deal with this problem. Hopefully, it will require some server restart from time to time, and we actually have some ideas to automate it in the future.

In particular, the `String.to_atom/1` function is not available in the console, in order to prevent a massive creation of atoms in a programatic way. Given this and other limitations, we expect that the atoms list will growth relatevely slow, giving us (the administrators) time to restore the server, if this ever needed.

# Other limitations

The execution of code in this console is limited by the backend logic in additional ways in an attempt to preserve the server health and able to attend a larger number of users.

Each submitted command should run in a limited number of seconds, otherwise a timeout error is returned. Moreover, the execution of the command must respect a memory usage limitation.

The lenght of the command itself (the number of characters) is limited as well. This restriction was added for security and resource saving reasons.

# Roadmap

Although we don't have a refined ongoing plan yet, we do have a list of possible improvements to do.

  * Extract the Elixir Sandbox funtionality to its own package.
  * Allow to spawn a limited amount of processes.
  * Sandboxed versions of some restricted modules and functions (e.g. in memory implementation of file maniputation functions). 
  * "Sandboxed atoms" (we have some ideas to solve the atoms usage problem, still working on a prototype to confirm if this is feasible).
  * Provide controlled access to additional concurrency-related functionality (`send`/`receive`, `Agent`, `GenServer`), if possible.

# About this project

This project was originally implemented to participate in the [Phoenix Phrenzy](https://phoenixphrenzy.com) contest.
It is an example of what can be built with [Phoenix](https://phoenixframework.org/) and [LiveView](https://github.com/phoenixframework/phoenix_live_view).

Beyond its main purpose, this is also an experimental project. In particular, we are interested on doing additional research around the idea of having a way to run untrusted Elixir code in a sandboxed manner, relying on an Elixir-only solution (one that could be provided as a package). 

The authors of the project are [Noelia](https://github.com/noelia-lencina), [Ignacio](https://github.com/iaguirre88), [Javier](https://github.com/JavierM42) and [Jorge](https://github.com/jmbejar). Special thanks to [WyeWorks](https://www.wyeworks.com WyeWorks) for providing working hours to be dedicated to this project.

# Contributing

Everyone is invited to open issues or pull requests that help us to extend and improve the Elixir Web Console. All contributions will be welcomed :tada:

Given the nature of the problem, we feel that security vulnerabilities actually exist. If you have found any related issue, please let us know privatelly at [elixirconsole@wyeworks.com](mailto:elixirconsole@wyeworks.com). We think that the strong Elixir community can play a relevant role helping us to keep this website robust and safe :muscle:.
