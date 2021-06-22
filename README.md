# Codespaces SOCKS proxy demo

This demonstrates how to use SSH and a local Docker container with a SOCKS proxy in it to allow a Codespace to access IPs on your local network.

> **Note:** This is a proof of concept rather than an offical implementation. Any offical implementation here would be more transparent than this illustrates.
>
> In addition, DNS or UDP forwarding are not wired in yet, though this is possible.

## Usage

### Codespace setup
1. Create a codespace from this repository
2. Connect to the codespace from VS Code client (not the web)
4. Open a terminal and run `sudo passwd $(whoami)` and set a SSH password
5. Take note of the username in the terminal - this image uses `vscode`, but it could be `codespaces` or `node` if you pick a different one.
6. Click on the "Ports" tab to see what port SSH ended up on locally - by default this would be port `2222`.

### Local setup
1. Install Docker Desktop (macOS/Windows) or Docker CE (on Linux) locally
2. Clone this repository locally
3. **[Recommended]** If you only want to proxy certain IPs to your local network, update `ips-to-proxy.conf` with a list (e.g. `10.130.128.0/8`). The default will proxy **everything**... including calls to github.

### Connecting
1. Connect to the codespace in VS Code client if you are not already
2. Open a *local* terminal and go to where you have cloned this repository
3. Run `./ssh-proxy vscode 2222` replacing `vscode` with the username for the image and `2222` with the local SSH port
4. When prompted, enter the password you configured

At this point, you can go into the terminal inside the codespace and hit local IPs you've configured.

### Troubleshooting
If something went wrong and the codespace stops working, just stop it and start it again. That will wipe out all config.  While connected to the codespace you can also run `sudo proxy-reset` from the integrated terminal to reset.

## How it works

Here's what happens:

1. Locally, a SOCKS5 capabile proxy is spun up in a Docker container (see the [Dockerfile here](https://github.com/Chuxel/codespaces-proxy/blob/master/src/proxy/Dockerfile)). Technically any SOCKS capable proxy could be used - this is just easy to get up and running. By default, the container makes the proxy available on port 4040.

2. In the codespace, a SSH server is started when the container starts.

3. When you connect to the codespace from VS Code, the SSH port (running on 2222) is forwarded to your local machine (via forwardPorts in [devcontainer.json](https://github.com/Chuxel/codespaces-proxy/blob/master/.devcontainer/devcontainer.json)).

4. Next, the local proxy's port (4040 by default) is reverse forwarded into the codespace using SSH (via `ssh -R`). This makes the SOCKS proxy available inside the container on a port (1080 by default).

5. Finally, a script is run via SSH to configure the codespace to use the forwarded SOCKS proxy. It:
    1. Installs the `redsocks` and `iptables` packages if missing - The `redsocks` package will allow the script to wire the proxy directly into the network stack via `iptables`.
    2. Uses `iptables` to redirect certain IP destinations to `redsocks`.
    3. Tweaks a `redsocks` configuration file so it connects to the port that SSH forwaded the local SOCKS proxy was forwaded to (1080 by default).
    2. Starts the `redsocks` daemon so it can start processing.

# License
Copyright (c) Microsoft Corporation. All rights reserved. <br />
Licensed under the MIT License. See [LICENSE](./LICENSE).
