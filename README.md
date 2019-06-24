Masterchef
==========

A simple boilerplate to help you run chef-solo.

## How it works

What Masterchef does is pretty straightforward. It uploads your cookbooks to remote machine, resolve dependencies then run chef-solo. All the heavy works are done in remote machine so you don't have to send your entire cookbooks and its dependencies. It also run pretty fast!

## How dependencies are resolved

Currently Masterchef uses [Berkshelf](https://github.com/berkshelf/berkshelf) to resolve cookbooks dependencies. If you write your cookbooks dependencies in your cookbook's `metadata.rb`, Masterchef will automagically resolve them.

If you don't want to put your dependencies into cookbook's `metadata.rb`, you can also put them in [workspace/Berksfile](workspace/Berksfile).

## What it is actually doing

Provision of a remote machine is done by:

1. Send content of [workspace/](workspace/) to remote machine with generated `attributes.json` from relevant machine configuration in [nodes/](nodes/).

1. Run `berks install` to resolve cookbooks dependencies for all cookbooks in [workspace/cookbooks/](workspace/cookbooks/).

1. Run `chef-solo` using generated `attributes.json`.

## Licence

MIT Licence
