gelfPush
========

Daemon to push log messages to Graylog2 via GELF

System requirements
* EPEL repository

Perl modules you'll need (RPM Package names)
* Config::INIFiles (perl-Config-IniFiles.noarch)
* JSON::XS
* File::Tail (perl-File-Tail.noarch)

How to use
* Move GelfPush.pm into your perl @INC path
  * Change the paths in GelfPush.pm to the production log files (Will be changed to be defaults in release)
* Create /etc/gelfPush.conf from the gelfPush.conf-example file
  * Change gelfPush.pl to use the correct config path (This will be an option in future releases)
* Run gelfPush.pl

More on configuration and runtime instructions to come.