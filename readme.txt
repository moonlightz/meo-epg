
DVBGuide 0.96 beta
------------------

(c) Copyright 2006-2012  Conquest Consultants


23rd September 2012


Introduction
~~~~~~~~~~~~
This beta version is released as a precursor to a new full release of DVBGuide.  The documentation included here refers to the last full release (i.e. 0.90) and therefore does not cover new features present in this beta release.  As usual, entering "DVBGuide -?" on the command will display a usage message that summarises all command line options (i.e. including new options present in this beta).

The main reason for classifying this release as a beta is because the user documentation has not been updated. With the exception of the documentation, this release should be considered as a better and more fully featured release than version 0.90 or any previous beta version.

The latest version of DVBGuide can always be found at www.dvbguide.com


Changes
~~~~~~~
The main changes since version 0.90 are:

(The following introduced in beta releases prior to 0.95)

* Revised signal lock/acquisiation mechanism (yet again!) for better compatibility with a minority of tuners;

* Generation of Guide data in MXF format for direct loading into Windows 7 using Microsoft supplied "loadmxf" utility;

* Support for channel logo references in Windows 7 MXF data;

* Updated decode tables (based on observed broadcasts to date) for the UK's Freesat EPG;

* Various minor improvements to the meta data accompanying programme descriptions in the generated Guide data.

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

* New feature: LNB parameters may now be specified on the command line (Ku band universal LNB assumed if not specified);

* Comment ("cpcm") added to XMLTV output to show FTA content management information where present;

* Channel identifiers in XMLTV file changed to dotted ONID.TSID.SID format (which should make it easier to combine XMLTV files from different runs of DVBGuide);

* Fixed invalid numbers in CSV table output for cases where delivery descriptors are missing;

* Increased timeout during DVB-S tuning phase (fixes a problem with some tuners and Windows 7);

* Bug fix: data items re-ordered in XMLTV file so as to strictly adhere to the schema (fixes problem with <language> node being in the wrong place);

* Updated decode tables (based on observed broadcasts to date) for the UK's Freesat EPG;


(Specific changes from version 0.95 to 0.96)
* Further increase to DVB-S post-tuning delay to fix problems observed on Windows 7

* Updated decode tables (based on observed broadcasts to date) for the UK's Freesat EPG;

* Default DVB-T carrier frequency changed to that of BBC mux A from Crystal Palace, post Digital Switch Over

* Changed output XML versions to 1.1 to allow full range of control codes

* Video information now shows SD, HD or SD upscaled

* CRID default authority information now taken from BAT or NIT if not present in SDT

* Other minor improvements.



Feedback
~~~~~~~~
This is beta software so bugs are entirely possible!  However, we are interested in your feedback so please report problems to: support@dvbguide.com
