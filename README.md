# chromium-remote-debuggable

A small Docker image and helper pattern to run Chromium (or Chrome) in a container while exposing a remote DevTools debugging port to other machines using socat.

Why this exists
---------------
Chromium/Chrome removed the ability to bind the DevTools remote debugging server to all interfaces using the `--remote-debugging-address=0.0.0.0` flag for security reasons. That makes running headless Chromium in containers and remotely accessing DevTools more difficult.

This project provides a lightweight workaround: run Chromium inside a container with DevTools bound to localhost, and use `socat` inside the container to forward the DevTools Unix/localhost socket (or TCP port) to 0.0.0.0 so external hosts can connect. The image is intentionally minimal and documents how to build and run it safely.

Features
--------
- Runs Chromium (or Google Chrome) inside a Docker container
- Uses `socat` to forward DevTools debugging from localhost to 0.0.0.0
- Example `docker run` and `docker-compose.yml` provided
- Notes on security and recommended production precautions

Quick summary / contract
------------------------
- Inputs: Dockerfile (this repo) and optionally a local Chromium binary or a base image with Chromium installed.
- Outputs: a Docker image exposing a remote DevTools TCP port (default 9222) accessible from other hosts.
- Success: You can connect your local Chrome/DevTools to the remote container's DevTools endpoint and debug pages running inside the container.
- Errors: If socat or Chromium fail to start, check container logs and make sure no host firewall or Docker network rule blocks the port.

Usage
-----
Build the Docker image (from repository root):

```pwsh
docker build -t chromium-remote-debuggable .
```

Run the container exposing port 9222 (DevTools) and optionally a web app port (example 3001):

```pwsh
docker run --rm -p 9222:9223 -p 3001:3001 --name chromium-debug chromium-remote-debuggable
```

Open DevTools on your host by navigating to:

		http://localhost:9222/

or use remote debugging protocols from other tools (e.g., Puppeteer with the `--remote-debugging-port=9222` flag).

Docker Compose example
----------------------
Below is a simple `docker-compose.yml` demonstrating how to run the image alongside a web service. Place this next to your repository if you want an example setup.

```yaml
version: '3.8'
services:
	chromium:
		image: chromium-remote-debuggable
		build: .
		ports:
			- "9222:9223"
		# For security: do not publish 9222 in production without network controls

	app:
		image: my-app:latest
		ports:
			- "8080:8080"
		depends_on:
			- chromium
```

How it works (high level)
-------------------------
1. Chromium is started inside the container with the DevTools remote debugging enabled and bound to localhost only.
2. `socat` is started inside the same container to forward traffic from 0.0.0.0:9222 to the Chromium's localhost DevTools endpoint.
3. The container publishes port 9222 so that other machines can connect to DevTools through the forwarded port.

Verification
------------
After starting the container, verify it's listening:

```pwsh
docker ps    # find the running container name or id
docker logs chromium-debug
```

On the host, open:

		http://localhost:9222/

You should see the DevTools frontend listing inspectable targets. If you use a remote host, replace `localhost` with the container host's IP or DNS name.

Security notes (important)
-------------------------
- Exposing DevTools remotely grants powerful control over the browser and any pages it loads. Do not expose port 9222 to untrusted networks.
- Prefer restricting access via firewall rules, SSH tunnels, VPN, or docker network controls.
- Consider adding basic auth, a reverse proxy, or limiting the container to a private network when debugging across hosts.
- Treat this image as a developer tool, not a production-facing service.

Implementation notes
--------------------
- This repository intentionally keeps the image minimal. The Dockerfile included in this repository should install `socat`, a Chromium binary or use a stable base image that includes Chromium, and a simple entrypoint that launches both Chromium and socat.
- If you want to use Puppeteer or Playwright, pass the remote debugging port to those tools or configure their launch options to connect to the exposed DevTools endpoint.

Base image reference
--------------------
For more details on configuration check the original image docs:

	https://hub.docker.com/r/linuxserver/chromium

The linuxserver image is a good starting point if you want a prebuilt Chromium install and additional examples.

Troubleshooting
---------------
- If the DevTools page is empty or unreachable:
	- Ensure the container is up and not exiting (docker ps).
	- Check `docker logs <container>` for socat or Chromium errors.
	- Ensure no host firewall (Windows Defender, iptables equivalents) is blocking port 9222.
	- If using WSL2 or Docker Desktop on Windows, ensure you connect to the correct host IP (often `localhost` works when ports are published).

Contributing
------------
Contributions are welcome. Please file issues or pull requests for improvements, such as adding a secure proxy wrapper, examples for use with Puppeteer/Playwright, or automated tests.

License
-------
This project is provided under the MIT license. See the LICENSE file for details.

---

If you want, I can also:
- Add a `docker-compose.yml` file to this repo.
- Create a sample `Dockerfile` or entrypoint script that launches Chromium + socat (if one doesn't already exist).
- Add a quick example showing how to connect using Puppeteer.
