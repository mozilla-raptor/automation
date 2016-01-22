#!/usr/bin/env node

'use strict';

let service = require('@mozilla/raptor/node_modules/raptor-test/dist/es5/lib/service');

service({ serial: process.argv[2] })
  .then(device => device.getGeckoRevision())
  .then(console.log)
  .catch(console.error)
  .then(() => process.emit('complete'));
