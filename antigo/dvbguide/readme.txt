
DVBGuide 0.94 beta
------------------

(c) Copyright 2006-2010  Conquest Consultants


25th April 2010


Introduction
~~~~~~~~~~~~
This beta version is released as a precursor to a new full release of DVBGuide.  The documentation included here refers to the last full release (i.e. 0.90) and therefore does not cover new features present in this beta release.  As usual, entering "DVBGuide -?" on the command will display a usage message that summarises all command line options (i.e. including new options present in this beta).

The main reason for classifying this release as a beta is because the user documentation has not been updated. With the exception of the documentation, this release should be considered as a better and more fully featured release than version 0.90.

The main changes since version 0.90 are:

(The following introduced in beta releases prior to 0.94)

* Revised signal lock/acquisiation mechanism (yet again!) for better compatibility with a minority of tuners;

* Generation of Guide data in MXF format for direct loading into Windows 7 using Microsoft supplied "loadmxf" utility;

* Support for channel logo references in Windows 7 MXF data;

* Updated decode tables (based on observed broadcasts to date) for the UK's Freesat EPG;

* Various minor improvements to the meta data accompanying programme descriptions in the generated Guide data.

(Specific changes from version 0.93 to 0.94)

* EIT extended event descriptor information now included in Media Center output data;

* XMLTV file now makes use of the channel logo information (if a path to a directory containing logos is provided);

* Extra information included in XMLTV file as XML comments now includes DVB locators & component records;

* New output file format option to produce a compact XMLTV file without additional information in XML comments (reduces file size by around 30%);

* Support for UK Freeview & Freesat guidance information mapped to guidance attributes in Media Center MXF guide data (still a work in progress, not all guidance information is mapped);

* Default carrier frequency changed to 505833 kHz to precisely match the Crystal Palace MUX 1 frequency (fixes problems with some tuners that require the precise frequency);

* Universal LNB parameters now only set for DVB-S carrier frequencies that fall in the Ku band (further work is needed for a complete solution that works with all LNB types);

* Affiliate name set to "DVBGuide" in MXF data rather than broadcast provider (this makes it easier to identify DVBGuide as the source of listings data in Media Center);

* New tuner enumeration and busy detection mechanism that avoids upsetting other running applications using the tuner(s);

* Updated decode tables (based on observed broadcasts to date) for the UK's Freesat EPG;

* Other minor improvements.


Feedback
~~~~~~~~
This is beta software so bugs are entirely possible!  However, we are interested in your feedback so please report problems to: support@dvbguide.com
