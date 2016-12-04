'use strict';

const Hapi = require('hapi');
const Good = require('good');
const Inert = require('inert');
const Path = require('path');

const server = new Hapi.Server({
  connections: {
    routes: {
      files: {
        relativeTo: Path.join(__dirname, 'public')
      }
    }
  }
});

server.connection({ port: 3000 });

server.register(Inert, () => {});

server.register({
  register: Good,
  options: {
    reporters: {
      console: [{
        module: 'good-squeeze',
        name: 'Squeeze',
        args: [{
          response: '*',
          log: '*'
        }]
      }, {
      module: 'good-console',
      }, 'stdout']
    }
  }
}, (err) => {

  if (err) throw err;

  server.route({
    method: 'GET',
    path: '/{param*}',
    handler: {
      directory: {
        path: '.',
        redirectToSlash: true,
        index: true
      }
    }
  });

  server.start( (err) => {

    if (err) throw err;

    console.log(`Server running at ${server.info.uri}`);

  })
})


