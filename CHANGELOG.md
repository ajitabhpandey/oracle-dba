# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- 
### Changed
- 
### Removed
- 

## [0.2] - 2018-05-29
### Added
- Added the CHANGELOG.md file to keep track of changelog
- xe_backup.sh - Fixed the script to cleanup old DMP and log files
- temp_tablespace_usage.sh - Fixed column headings in the output
### Changed
- Renamed expdp_full.sh to xe_backup.sh
- Followed Google shell style guide (https://google.github.io/styleguide/shell.xml)

### Removed
- None

## [0.1] - 2017-06-04
### Added
- expdp_full.sh - Perform full backup of Oracle Database using expdp.
- daily_archive_log.sh - Archivelog generation of an oracle database on a daily basis.
- fra_usage.sh - Display the FRA usage.
- tablespace_free.sh - Displays the space usage of each tablespace in the database.
- temp_tablespace_usage.sh - Current usage of temporary tablespace(sort usage) by active users.


### Changed
- None

### Removed
- None