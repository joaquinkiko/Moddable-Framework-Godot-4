# Godot Moddable Framework

> **WARNING**: This was designed for Godot 4.4+, issues are possible in prior builds.

Provides framework for loading Shared Libraries, Resource Packs, and Mods at runtime, 
as well as a customizable export framework to facilitate new features 
(and automatic license file exporting as a bonus!).

## Platforms Supported

At this time only Windows and Linux, x86_32 and x86_64 are supported. I may add additonal
platform support in the future.

## Installing

Simply drop into 'res://addons/' directory in project, and enable plugin in Project Settings.

Note: On first enabling the plugin will generate some of the base files 
and directories used by the plugin within your Project directory. These filepaths can be
changed later in Project Settings.

## Goals

- Allow different builds to use different gdextensions (say steam build vs non-steam build) without much additional work from developer
- Clean up exported project directories when using lots of extensions, giving a more professional and organized look
- Split project into multiple .pck fies, bypassing current file size limitations, and potentially allowing for smaller patch sizes
- Allow additional extensions and .pck files to be loaded at runtime for modding support
- Give a flexible system for loading assets from a mix of filepaths, allowing assets to be overriden by mods
- Allow assets to be loaded from exported project directory, giving developers more flexibility on certain types of modding support
- Allow Static Globals (Globals that are not nodes, just static classes)
- BONUS: Automate license file generation for project exports

## How to use

### Asset Library



### Export Manager



### License Exporting



### New Extension System



### Multiple Resource Pack System



### Mod Manager
