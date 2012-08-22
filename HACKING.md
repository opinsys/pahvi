# Hacking pahvi

## Installation

Dependencies

    sudo apt-get install build-essential libssl-dev git-core graphicsmagick

Fetch and Build Node.js

    wget http://nodejs.org/dist/v0.6.21/node-v0.6.21.tar.gz
    tar xzvf node-v0.6.21.tar.gz
    cd node-v0.6.21
    ./configure
    make
    sudo make install

Fetch and build Pahvi

    git clone https://github.com/opinsys/pahvi.git
    cd pahvi
    npm rebuild

## Configuring

Move config.json-example to config.json and edit if necessary.

## Running the app

In development

    bin/develop

Node.js debugging

    bin/debug

Production

    export NODE_END=production
    npm start


## Directory conventions

Server-side code:

    lib/

Client-side code:

    client/

Client styles:

    client/styles/

Vendor bundles for the client (JS and CSS!):

    client/vendor/

Handlebars templates:

    views/

Client-side Handlebars templates:

    views/client

Random helper scripts

    bin/


[pyramid]: https://github.com/christkv/node-mongodb-native/blob/c5963250c2eda97ec958502da51a46e378e17f5b/examples/blog.js "Bad code!"



## Resources

  * CoffeeScript
    * http://coffeescript.org/
    * http://arcturo.github.com/library/coffeescript/
    * http://autotelicum.github.com/Smooth-CoffeeScript/
  * Backbone.js
    * http://documentcloud.github.com/backbone/
    * https://github.com/addyosmani/backbone-fundamentals
  * Handlebars.js
    * http://handlebarsjs.com/
  * Underscore.js
    * http://documentcloud.github.com/underscore/
  * Async.js
    * https://github.com/caolan/async
  * jQuery
    * http://jqapi.com/
    * http://docs.jquery.com/Main_Page
  * Node.js
    * http://nodejs.org/docs/latest/api/
  * Express
    * http://expressjs.com/
  * Cool Vim tricks ;)
    * http://esa-matti.suuronen.org/blog/2011/11/28/how-to-write-coffeescript-efficiently/





