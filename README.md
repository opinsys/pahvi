# Example Webapp

Base for building web applications with Node.js, CoffeeScript, Stylus, Backbone.js and Handlebars.js.

Cool stuff:

  * Uses Handlebars.js for both the server and client templating
  * Has buildin support for CSS live reloading
  * Asset management. Do not ever use preminified assets. Piler will do that for us


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
  * ...


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


## Running the app

In development

    bin/develop

Node.js debugging

    bin/debug

Production

    export NODE_END=production
    npm start


## Resources

  * Backbone.js
    * http://documentcloud.github.com/backbone/
    * https://github.com/addyosmani/backbone-fundamentals
  * Underscore.js
    * http://documentcloud.github.com/underscore/
  * Handlebars.js
    * http://handlebarsjs.com/
  * jQuery
    * http://jqapi.com/
    * http://docs.jquery.com/Main_Page
  * Node.js
    * http://nodejs.org/docs/latest/api/
  * Cool Vim tricks ;)
    * http://esa-matti.suuronen.org/blog/2011/11/28/how-to-write-coffeescript-efficiently/





