# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- TODO.md - a list of future aspirations for some brave spirit with both time and willingness

### Fixed
- fixed --list-models (@nickhilliard)
- return exception if host specification line returns no hosts (@nickhilliard)
- Remove Oxidized.setup_logger from CLI initialization (@nickhilliard)

## [0.7.0 - 2025-01-21]

### Added
- Added no-trim option (@Gman98ish)
- added rubocop config (@wk)
- added Github Actions from ytti/oxidized (@aschaber1)

### Fixed
- Normalise file permissions before push (@ytti)
- update gemspec dependencies (@nickhilliard)
- updates + sanity checking on gh actions (@nickhilliard)

## [0.6.0 - 2018-12-16]

### Added
- Implemented combination of regex with ostype (@LarsKollstedt)

### Fixed
- refactor some code (@ytti)
- updated oxidized dependency (@ytti)

## [0.5.1 - 2018-06-03]

### Fixed
- fixed oxidized dependency (@ytti)

## [0.5.0 - 2017-11-01]

### Fixed
- adding in sync for stdout giving more control over individual changes (@nertwork)

## 0.4.0
- FEATURE on --ostype to get a list of nodes that match a particular OS Type (junos, routeros, ios) (by InsaneSplash)

## 0.3.1
- FEATURE on --dryrun to get a list of nodes without running a command (by @nertwork)
- BUGFIX: errors with large config files running in ruby threads - forking instead (by @nertwork)

## 0.3.0
- FEATURE on --regex to run commands on hosts matching a regex (by @nertwork)
- FEATURE on -g to run commands on entire group (by @nertwork)
- FEATURE on -r to thread commands run on entire group (by @nertwork)
- BUGFIX: fix for replacing escaped newlines in config files (by @nertwork)

## 0.2.0
- FEATURE on -x disable ssh exec mode (by @nickhilliard)

## 0.1.2
- BUGFIX: fix for oxidized refactored code

## 0.1.1
- BUGFIX: initialize manager only once
