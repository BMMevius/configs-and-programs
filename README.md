# Config files and programs

This repo holds the installation and configuration files for everything that is needed to create a PC or laptop.
The kind of hardware determines which branch should be used.

The following branches are the currently up-to-date branches:

- master: holds the base installation without any assumption on GPU
- pc: adds GPU packages to the installation
- laptop: adds GPU packages and laptop specific packages to the installation
- laptop-personal: adds personal tools and programs to the installation
- work: adds work related tools and programs to the installation

The branch structure is as follows:

```shell
master
├── pc
└── laptop
    ├── laptop-personal
    ├── laptop-windows-theme
    └── work
```
