# gNodeB image

*Note: This README file has been written by Dr. Enrico Bassetti. We adapt it to only include the relevant information for running the stack on a local machine.*

The image built using the `Dockerfile` in this directory contains the software modem for the gNodeB. This image can be used in Intel-based environments using processors without AVX-512 instruction set. Refer to the main README for the motivation.

Differently from the official distribution, this image also embeds the example configurations that are available in the `PROJECTS` directory.

## Build the image

To build the image, use the following command:

```sh
docker build -t oai-gnodeb-local:2024-10-09 .
```

If needed, you can replace `2024-10-09` with a different tag. When using a different tag, update the tag also inside the `all-in-one/docker-compose.yml` file.
