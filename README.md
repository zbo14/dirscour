# dirscour

A recon tool for scanning a lot of web paths in parallel!

**WARNING:** do not use this tool to scan targets you aren't authorized to scan!

## Install

Clone the repo and `cd` into it.

## Usage

The way it works is you pass `dirscour` a domain or a file containing 1 domain per line.

In the former case, `dirscour` uses [amass](https://github.com/OWASP/Amass) to enumerate subdomains and then [dirsearch](https://github.com/maurosoria/dirsearch) to scan their web paths.

In the latter case, `dirscour` scans web paths for the domains listed in the file.

```
USAGE: ./dirscour [OPTIONS] <domain/@file>

OPTIONS:
  -h  log usage information and exit
  -c  run in Docker container
  -d  path to dirsearch directory
  -o  path to output directory
  -p  number of daemon processes to spawn (default: 20)
```

`dirscour` maintains a process pool for scanning web paths. When a process finishes scanning one domain, it scans the next (unscanned) domain. You can adjust the size of the process pool with the `-p` option.

If you don't have `amass` or `dirsearch` installed on your machine, you can still use `dirscour`. Just specify the `-c` flag and `dirscour` will run in a [Docker](https://docs.docker.com/get-docker/) container with all the necessary tooling. **Note:** this will build the Docker image if it doesn't exist.

If you already have the tools installed on your machine, you can run `dirscour` without Docker. Specify the `-d` option to point `dirscour` to the directory containing `dirsearch.py`.

You can also tell `dirscour` where to write scan results. Just include the `-o` option with the path to the output directory. Web paths for each domain will be written to `<output-directory>/reports/<domain>.txt`.

## Contributing

Do it!

Whether it's cleaning up code, adding another tool, or incorporating another recon technique, all contributions are welcome!

If you have an idea to make `dirscour` better, open an issue and/or create a pull request!
