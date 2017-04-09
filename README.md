# Archivebot

A slackbot written in `Elixir` which archives all the messages in the channels it is added to. It stores the messages in a Postgresql database.

This bot uses `Slack RTM` to receive and respond to messages. So no need to configure a webserver or domain for the bot. You can run this anywhere. It currently supports `Ubuntu` and `Centos`.

## Getting started

- You need `Postgresql` database installed and also a db named `slack_archives`. This is the db in which `archivebot` stores all the messages.
- Create a bot in Slack (which provides you a API token which needs to be added later) and add the bot 
- Just download the appropriate release from https://github.com/iamd3vil/archivebot/releases
- Extract the tar file and you will find a `archivebot.conf` file in `releases/archivebot/0.1.0/`
- This is the conf file you need to edit. See `Configuration Options` for different config options.
- After adding appropriate config you can start the bot by `bin/archivebot start`
- You can stop or restart the bot by running `bin/archivebot stop` or `bin/archivebot restart`.
- That's it you can find your messages archived in the Postgresql db.

## Configuration Options

- `slack.api_token` -> Give your bot API token here.
- `archivebot.username` -> Postgresql db username
- `archivebot.password` -> Postgresql db password
- `archivebot.hostname` -> Postgresql hostname

## Searching the archives

`Archivebot` also provides a way to search the archives. In a DM or any channel `archivebot` is in you can send a message saying `@archivebot /search hey man` where `hey man` is the search term. Archivebot will respond with the search results found in the archives.
