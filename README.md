[![Build Status](https://travis-ci.org/wyeworks/elixir_console.svg?branch=master)](https://travis-ci.org/wyeworks/elixir_console)
[![SourceLevel](https://app.sourcelevel.io/github/wyeworks/elixir_console.svg)](https://app.sourcelevel.io/github/wyeworks/elixir_console)

---

# Elixir Web Console

The [Elixir Web Console](https://elixirconsole.wyeworks.com/) is a virtual place where people can try the [Elixir language](https://elixir-lang.org/) without the need to leave the browser or installing it on their computers. While this is a project in its early stages, we hope this is a contribution to the effort to promote the language, providing a convenient way to assess the capabilities of this technology. We would love to hear ideas about how to extend this project to better serve this purpose (see the Contributing section).

This project is inspired in existing playground sites from distinct communities, such as [SwiftPlayground](http://online.swiftplayground.run/) and [Rust Playground](https://play.rust-lang.org/), Yet, it is unique because it aims to mimic the [Elixir interactive shell (iEX)](https://hexdocs.pm/iex/IEx.html).

# Features

*   Bindings are persisted through the current session. Users can assign values to variables. They will remain visible at the side of the screen.
*   Pressing the Tab key displays a list of suggestions based on what the user is currently typing in the command input. If only one option is available, the word is autocompleted. It will help to discover modules and public functions. Existing binding names are also taken into account to form the list of suggestions.
*   The console presents the history of executed commands and results. The sidebar will display the documentation of Elixir functions when the user clicks on them.
*   There is easy access to already-executed commands pressing Up and Down keys when the focus is in the command input.

![Elixir Web Console](https://media.giphy.com/media/JUM6QQWQWjDpA03MBv/giphy.gif "Elixir Web Console")

# Where my Elixir code is executed?

Unlike other playground projects, it does not rely on spawning sandbox nodes or additional servers to run the code. The Elixir application that is also serving the web page is also responsible for executing the user code.

Of course, there are plenty of security considerations related to the execution of untrusted code. However, we came up with a solution that allows us to execute them directly on our Elixir backend (see next section).

The system executes every submitted command in the context of a dedicated process. Note that subsequent invocations to `self()` will return the same PID value. Since this is an isolated process, the executed code should not interfere with the LiveView channel or any other process in the system.

# How much Elixir can I run in the web console?

As you might guess, not all Elixir code coming from unknown people on the internet is safe to execute in our online console. The system checks the code before running it. Code relying on certain parts of the language will cause an error message explaining the limitations to the user.

## Elixir safe modules and Kernel functions

The console has a whitelist including modules and functions of Elixir considered safe to execute. The system will inform about this limitation when users attempt to use disallowed stuff, such as modules providing access to the file system, the network, and the operating system, among others.

Moreover, the mentioned whitelist does exclude the metaprogramming functionality of Elixir. The functions [`Kernel.apply/2`](https://hexdocs.pm/elixir/Kernel.html#apply/2) and [`Kernel.apply/3`](https://hexdocs.pm/elixir/Kernel.html#apply/3) are also out of the whitelist to prevent the indirect invocation of not-secure functions.

## Processes

The console currently does not allow the usage of the module `Process` and other parts of Elixir related to processes. Existing resource usage limitations (see next section) would be much harder to enforce if users were permitted to spawn processes. Similarly, the functions `send` and `receive` are restricted to avoid integrity and security problems.

**This limitation does not make us happy** because it would be valuable to let people play with processes within our interactive shell. We are currently thinking about manners to include those modules and functions within the whitelist. Extra precaution is needed to implement it due to possible security implications.

## The problem with atoms

It represents a tricky issue for our web console because in Elixir/Erlang atoms are never garbage collected. Therefore, each atom created by users code will be added to the global list of existing atoms. It means that, eventually, the [maximum number of atoms](http://erlang.org/doc/efficiency_guide/advanced.html#atoms) will be reached, causing a server crash.

We consider this issue is not an impediment to have the server operating, at least for now. In case of a crash due to the overflow of atoms, Heroku will automatically restart the application.

When the server is restarted any existing sessions are lost. Of course, it would be problematic if it happens often. We are monitoring the server to better diagnose the relevance of this issue. Hopefully, it will require some server restart from time to time, and we have some ideas to automate it in the future.

To mitigate this problem, the function `String.to_atom/1`  is not available in the console limiting the creation of a large number of atoms programmatically.

We are confident that the number of created atoms will growth relatively slow, giving us time to restore the server if this is ever needed.

# Other limitations

The execution of code in this console is limited by the backend logic in additional ways in an attempt to preserve the server health and able to attend a larger number of users.

Each submitted command should run in a limited number of seconds, otherwise, a timeout error is returned. Moreover, the execution of the command must respect a memory usage limit.

The length of the command itself (the number of characters) is limited as well. This restriction was added for security and resource-saving reasons.

# Roadmap

While a refined ongoing plan does not exist yet, the following is a list of possible improvements.

*   Extract the Elixir Sandbox functionality to a package.
*   Allow spawning a limited amount of processes.
*   Sandboxed versions of certain restricted modules and functions. For example, a fake implementation of the filesystem functions.
*   Provide controlled access to additional concurrency-related functionality (send/receive, Agent, GenServer), if possible.
*   There are ideas to overcome the problem with atoms. We are still working on a prototype to confirm if this is feasible.

# About this project

This project was originally implemented to participate in the [Phoenix Phrenzy](https://phoenixphrenzy.com) contest.  It is an example of the capabilities of [Phoenix](https://phoenixframework.org/) and [LiveView](https://github.com/phoenixframework/phoenix_live_view).

Beyond its main purpose, this is a research initiative. We are exploring the implications of executing untrusted Elixir code in a sandboxed manner. In particular, we want to solve it without using extra infrastructure, being as accessible and easy to use as possible. We have plans to create a package including the sandbox functionality. This package would enable the usage of Elixir as a scripting language (although we are not sure if this is a good idea).

The authors of the project are [Noelia](https://github.com/noelia-lencina), [Ignacio](https://github.com/iaguirre88), [Javier](https://github.com/JavierM42) and [Jorge](https://github.com/jmbejar). Special thanks to [WyeWorks](https://www.wyeworks.com) for providing working hours to dedicate to this project.

# Contributing

Please feel free to open issues or pull requests. Both things will help us to extend and improve the Elixir Web Console  🎉
Given the nature of the problem, we know that security vulnerabilities probably exist. If you have found a security problem, please send us a note privately at [elixirconsole@wyeworks.com](mailto:elixirconsole@wyeworks.com).

# License

Elixir Web Console is released under the [MIT License](https://github.com/wyeworks/elixir_console/blob/master/LICENSE.md).
