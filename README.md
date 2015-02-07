shadowsocks-gui
===============

Yale Huang's clone of shadowsocks-gui, works with Ubuntu 14.04 (and maybe
earlier versions).

GUI for shadowsocks, powered by [shadowsocks-nodejs](https://github.com/clowwindy/shadowsocks-nodejs)

OSX / Windows / Linux

![Screenshot](https://raw.github.com/yaleh/shadowsocks-gui/master/screenshot.png)

Download
--------

TODO.

Develop
-------

Clone the repo and install dependencies:

    git clone https://github.com/yaleh/shadowsocks-gui.git
    cd shadowsocks-gui
    npm install

Download [node-webkit](https://github.com/rogerwang/node-webkit#downloads)

Then copy unzipped files into shadowsocks-gui directory. Then run nw.exe / node-webkit.app / nw

See also: https://github.com/rogerwang/node-webkit/wiki/How-to-run-apps

Build
-----

Grunt and bower are required for building:

    npm install -g grunt-cli bower

There are two types of building: production and debug.

Production build:

    grunt

Debug build:

    grunt debug

Clean:

    grunt clean

Run
---

    nw .

License
--------

[MIT License](https://raw.github.com/shadowsocks/shadowsocks-gui/master/LICENSE)

Server and other clients
---------

Server and other clients can be found [here](https://github.com/clowwindy/shadowsocks/wiki/Ports-and-Clients).


Bugs and Issues
----------------
Please visit [issue tracker](https://github.com/shadowsocks/shadowsocks-gui/issues?state=open)

Mailing list: http://groups.google.com/group/shadowsocks
