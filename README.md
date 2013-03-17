PerlAutomation
==============

Simple Home Automation Running on AnyEvent Twiggy with Dancer and Socket.io.js

What is it?
-----------

This is an example of a event driven home automation program with a real time web interface.
Websockets are used to provide real time updates to the web page, but if they are not available
(for instance, on the Android browsers) the program falls back on other transport methods
suchs as long-polling Ajax.

Currently this is at more of a tech demo level, only the Vera home automation controllers is supported,
and that support is partial (Vera Binary, Dimmable, and Security Sensors are handled, and errors
in fetching data from Vera are not handled at all).  

All other device support is incomplete (Denon receivers, X10, ...)

Instructions
------------

This depends on quite a few packages from CPAN (Moose, AnyEvent, Dancer, etc).

Once those are installed modify the IP address of Vera in bin/PerlAutomation.pl

Run with: the bin/run script or:

plackup --server Twiggy -p 5000 PerlAutomation.pl
