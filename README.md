# Volatility Windows Analysis Script

This script is designed to simplify the process of forensic investigation on Windows memory dumps using Volatility 3 and Volatility 2. It provides a quick and easy way to get a comprehensive first glance at a memory dump, running multiple plugins and organizing the output for easy analysis.

## Features

- Runs a set of common Volatility 3 plugins for Windows memory analysis
- Option to dump files using Volatility 3's windows.dumpfiles plugin
- Option to dump registry using Volatility 2
- Generates a summary report of the analysis
- Calculates MD5 checksum of the memory dump
- Flexible output directory specification

## Prerequisites

- Volatility 3 installed and accessible via `vol` command
- Volatility 2 installed (optional, for registry dumping)
- Bash shell environment

## Setup

Before running the script, you may need to set up an alias for Volatility 2. If Volatility 2 is not in your system PATH, you can set the following environment variable:

```bash
export VOLATILITY2_ALIAS='/opt/tools/volatility/venv/bin/python2 /opt/tools/volatility/vol.py'
```

Add this line to your `.bashrc` or `.bash_profile` to make it permanent.

## Usage

```bash
./volatility-windows-analysis.sh <memory_dump> [output_directory] [options]
```

### Arguments:

- `<memory_dump>`: Path to the memory dump file (required)
- `[output_directory]`: Directory to store output (optional, default: volatility_output)

### Options:

- `--dump-registry`: Run only the Volatility 2 registry dump
- `--dump-files`: Include windows.dumpfiles plugin in the analysis

### Examples:

1. Run full analysis:
   ```
   ./volatility-windows-analysis.sh memory_dump.raw
   ```

2. Specify output directory:
   ```
   ./volatility-windows-analysis.sh memory_dump.raw /path/to/output
   ```

3. Only dump registry:
   ```
   ./volatility-windows-analysis.sh memory_dump.raw --dump-registry
   ```

4. Only dump files:
   ```
   ./volatility-windows-analysis.sh memory_dump.raw --dump-files
   ```

5. Dump both registry and files:
   ```
   ./volatility-windows-analysis.sh memory_dump.raw --dump-registry --dump-files
   ```

## Output

The script creates a directory structure containing the output of each Volatility plugin run. A summary report is generated, and if requested, dumped files and registry hives are saved in their respective directories.

## Note

This script is intended as a starting point for forensic analysis. Always verify the results and perform additional investigation as needed for a thorough analysis.

## Contributing

Contributions, issues, and feature requests are welcome. Feel free to check [issues page](https://github.com/gl0bal01/volatility-windows-analysis/issues) if you want to contribute.

## License

[GPL-3.0 license](LICENSE)
