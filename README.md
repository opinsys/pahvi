# Example Webapp

Base for building web applications with Node.js, Backbone.js and Handlebars.js.

Uses Handlebars.js for both the server and client templating.


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
    * http://docs.jquery.com/Main\_Page
  * Node.js
    * http://nodejs.org/docs/latest/api/





