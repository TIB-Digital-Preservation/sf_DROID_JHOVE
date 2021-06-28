# File Format Identification and Validation

The Skript performs File Identification with sf and DROID, and validates the files with Jhove.

# Prerequisites
The following tools must be installed:
- [siegfried](https://www.itforarchivists.com/siegfried/)
- [DROID](https://www.nationalarchives.gov.uk/information-management/manage-information/preserving-digital-records/droid/), Options: MayByteScan -1, do not extract archive files 
- [JHOVE](https://openpreservation.org/products/jhove/)

For windows:
cygwin with perl modules

All three must be named in the Enrivonment Variables.

# Usage

Adapt the paths to the input directory and the output directory in the script.
Use cygwin to start the script with the command 'perl sfDroidJhove.pl'

## Authors
 
* **Merle Friedrich** - *German Nation Library of Science and Technology (TIB)*
 
## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details