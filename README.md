#  Tor Buildah Image
Goal is to provide containerized Tor daemon that would be available for use in combination with other programs to create secure onion services.

**WARNING: This does not protect you if you do stupid things and you can't hold the author of this repo responsible if you don't understand what you're doing**
## Requirements 

- [buildah](https://github.com/containers/buildah/blob/main/install.md) on build host
- [podman](https://podman.io/getting-started/installation#linux-distributions) on the host where this image is going to be run
- git on build host
- ar   on build host (The GNU ar program creates, modifies, and extracts from archives)
- [distroless image](https://console.cloud.google.com/gcr/images/distroless/global/base) sha256 value
- [tor](https://github.com/torproject/tor/releases) release tag and sha commit ID

## Build Tor base image
Before starting the build process we need to have the required shared libraries bundled with the distroless image that we are going to use as a base image

```
git clone https://github.com/Far1za/tor-buildah.git
cd tor-buildah
```

Navigate to [distroless ](https://console.cloud.google.com/gcr/images/distroless/global/base) image repo and filter out the **nonroot** image available for your architecture.

Edit **base_image.sh** and update the variables listed below to reflect the correct values.

SHA256=**"sha256:a74f307185001c69bc362a40dbab7b67d410a872678132b187774fa21718fa13"**  
DEB_ARCH=**"amd64.deb"** (set to target architecture *example: amd64,arm,arm64 etc.*)  
TAG=**tor-base-image:x86_64** (this once is optional, comment out if you prefer to deal with ImageID directly)

	./base_image.sh # execute the script to generate the required base image with the shared libraries

**NOTE:** this step can be used to create other custom base images based on the distroless image

Once you have you base image edit **Dockerfile** or **Dockerfile.arm64** if you target other architecture other then the default where buildah is being run.

ARG TOR=**tor-0.4.6.7**  
ARG HASH=**31728f4ad386042d3088f015e28f15d91ae3e283**  
FROM **tor-base-image:x86_64**

*Dockerfile.arm64 specific, targeting the destination host architecture*
ARG HOST=**aarch64**  
ARG ARCH=**arm64**

Save your changes and start the build process.

	buildah bud --timestamp 0 -f Dockerfile(.arm64)
	
Note the resulting **ImageID** as we are going to use it in the next step

## Putting it all together

Now that we have our Tor image we need to make it available on our target host where we plan to run it.

```
# This is needed if the host where tor is going to run is different from our build host
buildah push imageID oci-archive:/path/to/archive:image:tag
scp archive username@IP_ADDR:/home/username
```

**NOTE:** it is possible to push the image to some repository and later pull from there,but to keep it simple and private we would use the approach explained above.

Now that we have our image on the target host we can create our new instance

```
podman pod create --name pod_name # create new pod with the desired name
podman create -v ~/service:/tor/share/service -v ~/torrc:/tor/etc/tor/torrc --pod pod_name ImageID
# add all other images that need to run inside the same pod
# service is the name of the Dir where we are going to store the v3 onion address data and needs to exist
```

Now that we have created our pod we need to change permissions on our host so they are compatible from inside the container. 
```
chmod 700 ~/service
podman unshare chown -R 65532:65532 ~/service
```
Read [rootless-podman-makes-sense](https://www.redhat.com/sysadmin/rootless-podman-makes-sense) for a better explanation on the topic.

```
podman pod start pod_name  #start our newly created pod
podman pod ps --ctr-status #get pod and container status
```

If everything is configured correctly we should get a status **running** on our containers. 
Otherwise we would need to parse the logs generated from the failed containers to determine what is wrong.

```
podman ps --all # get container status
podman logs ContainerID
```
## Pod Auto start

To save ourselfs from manual start of the pod every time we reboot our host we can generate a systemd script that is going to start the pod for us

	podman generate systemd --files --name pod_name

## Support

If you have any issues or suggestions for improvements please open a new issue.
Otherwise if this has helped you to realize your project or saved you from extra work please express your appreciation here

	monero:88nYxA5xZEfLDuTPiBXZuzMRKFzHsR6JJSnBoNkJb9rF16KZxtYzFHJcZoaFKAbeUxXtPUQgjZ6zj7y5WBiP5c8vCXP5r8N

Thank you.
