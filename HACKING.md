# Hacking pahvi


## Directories

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

## Conventions (proposal)

  * Use two spaces for indentation everywhere
  * camelCase for CSS classes and IDs
  * camelCase for CoffeeScript variables and properties
  * UpperCamelCase for CoffeeScript classes
  * Max 79 characters per line. Keeps [pyramid of doom][pyramid] away :)

[pyramid]: https://github.com/christkv/node-mongodb-native/blob/c5963250c2eda97ec958502da51a46e378e17f5b/examples/blog.js "Bad code!"


## Installing Node.js

Build dependencies

    sudo apt-get install libssl-dev

Build

    cd /tmp/
    wget http://nodejs.org/dist/latest/node-v0.6.7.tar.gz
    tar xzvf node-v0.6.7.tar.gz
    cd node-v0.6.7
    ./configure
    make
    sudo make install



## Installing Webapp dependencies

    npm install
    sudo apt-get install graphicsmagick

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





