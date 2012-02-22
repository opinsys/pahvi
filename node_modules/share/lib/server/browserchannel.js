var browserChannel, hat, syncQueue, util;

browserChannel = require('browserchannel').server;

util = require('util');

hat = require('hat');

syncQueue = require('./syncqueue');

module.exports = function(model, options) {
  options || (options = {});
  return browserChannel(options, function(session) {
    var buffer, bufferMsg, client, close, data, docState, handleClose, handleMessage, handleOp, handleOpenCreateSnapshot, lastReceivedDocName, lastSentDocName, open, send;
    console.log("New BC session from " + session.address + " with id " + session.id);
    data = {
      headers: session.headers,
      remoteAddress: session.address
    };
    client = null;
    lastSentDocName = null;
    lastReceivedDocName = null;
    docState = {};
    handleMessage = function(query) {
      var lastReceivedDoc, _name;
      console.log("Message from " + session.id, query);
      if (query.doc === null) {
        query.doc = lastReceivedDoc = hat();
      } else if (query.doc !== void 0) {
        lastReceivedDoc = query.doc;
      } else {
        if (!lastReceivedDoc) {
          console.warn("msg.doc missing in query " + (JSON.stringify(query)) + " from " + client.id);
          return session.abort();
        }
        query.doc = lastReceivedDoc;
      }
      docState[_name = query.doc] || (docState[_name] = {
        queue: syncQueue(function(query, callback) {
          if (!docState) return callback();
          if (query.open === false) {
            return handleClose(query, callback);
          } else if (query.open || query.snapshot === null || query.create) {
            return handleOpenCreateSnapshot(query, callback);
          } else if (query.op != null) {
            return handleOp(query, callback);
          } else {
            console.warn("Invalid query " + (JSON.stringify(query)) + " from " + client.id);
            session.abort();
            return callback();
          }
        })
      });
      return docState[query.doc].queue(query);
    };
    send = function(response) {
      var lastSentDoc;
      if (response.doc === lastSentDoc) {
        delete response.doc;
      } else {
        lastSentDoc = response.doc;
      }
      if (session.state !== 'closed') {
        console.log("Sending", response);
        return session.send(response);
      }
    };
    open = function(docName, version, callback) {
      var listener;
      if (!docState) return callback('Session closed');
      if (docState[docName].listener) return callback('Document already open');
      docState[docName].listener = listener = function(opData) {
        var opMsg;
        if (docState[docName].listener !== listener) {
          throw new Error('Consistency violation - doc listener invalid');
        }
        if (opData.meta.source === client.id) return;
        opMsg = {
          doc: docName,
          op: opData.op,
          v: opData.v,
          meta: opData.meta
        };
        return send(opMsg);
      };
      return model.clientOpen(client, docName, version, listener, callback);
    };
    close = function(docName, callback) {
      var listener;
      if (!docState) return callback('Session closed');
      listener = docState[docName].listener;
      if (listener == null) return callback('Doc already closed');
      model.removeListener(docName, listener);
      delete docState[docName].listener;
      return callback();
    };
    handleOpenCreateSnapshot = function(query, finished) {
      var callback, docData, docName, msg, step1Create, step2Snapshot, step3Open;
      docName = query.doc;
      msg = {
        doc: docName
      };
      callback = function(error) {
        if (error) {
          if (msg.open === true) close(docName);
          if (query.open === true) msg.open = false;
          if (query.snapshot !== void 0) msg.snapshot = null;
          delete msg.create;
          msg.error = error;
        }
        send(msg);
        return finished();
      };
      if (query.doc == null) return callback('No docName specified');
      if (query.create === true) {
        if (typeof query.type !== 'string') {
          return callback('create:true requires type specified');
        }
      }
      if (query.meta !== void 0) {
        if (!(typeof query.meta === 'object' && Array.isArray(query.meta) === false)) {
          return callback('meta must be an object');
        }
      }
      docData = void 0;
      /*
            model.clientGetSnapshot client, query.doc, (error, data) ->
              maybeCreate = (callback) ->
                if query.create and error is 'Document does not exist'
                  model.clientCreate client, docName, query.type, query.meta or {}, callback
                else
                  callback error, data
      
              maybeCreate (error, data) ->
                if query.create
                  msg.create = !!error
                if error is 'Document already exists'
                  msg.create = false
                else if error and (!msg.create or error isnt 'Document already exists')
                  # This is the real final callback, to say an error has occurred.
                  return callback error
                else if query.create or query.snapshot is null
      
      
                if query.snapshot isnt null
      */
      step1Create = function() {
        if (query.create !== true) return step2Snapshot();
        if (docData) {
          msg.create = false;
          return step2Snapshot();
        } else {
          return model.clientCreate(client, docName, query.type, query.meta || {}, function(error) {
            if (error === 'Document already exists') {
              return model.clientGetSnapshot(client, docName, function(error, data) {
                if (error) return callback(error);
                docData = data;
                msg.create = false;
                return step2Snapshot();
              });
            } else if (error) {
              return callback(error);
            } else {
              msg.create = !error;
              return step2Snapshot();
            }
          });
        }
      };
      step2Snapshot = function() {
        if (query.snapshot !== null || msg.create === true) {
          step3Open();
          return;
        }
        if (docData) {
          msg.v = docData.v;
          if (query.type !== docData.type.name) msg.type = docData.type.name;
          msg.snapshot = docData.snapshot;
        } else {
          return callback('Document does not exist');
        }
        return step3Open();
      };
      step3Open = function() {
        if (query.open !== true) return callback();
        if (query.type && docData && query.type !== docData.type.name) {
          return callback('Type mismatch');
        }
        return open(docName, query.v, function(error, version) {
          if (error) return callback(error);
          msg.open = true;
          msg.v = version;
          return callback();
        });
      };
      if (query.snapshot === null || (query.open === true && query.type)) {
        return model.clientGetSnapshot(client, query.doc, function(error, data) {
          if (error && error !== 'Document does not exist') return callback(error);
          docData = data;
          return step1Create();
        });
      } else {
        return step1Create();
      }
    };
    handleClose = function(query, callback) {
      return close(query.doc, function(error) {
        if (error) {
          send({
            doc: query.doc,
            open: false,
            error: error
          });
        } else {
          send({
            doc: query.doc,
            open: false
          });
        }
        return callback();
      });
    };
    handleOp = function(query, callback) {
      var op_data;
      op_data = {
        v: query.v,
        op: query.op
      };
      return model.clientSubmitOp(client, query.doc, op_data, function(error, appliedVersion) {
        var msg;
        msg = error ? {
          doc: query.doc,
          v: null,
          error: error
        } : {
          doc: query.doc,
          v: appliedVersion
        };
        send(msg);
        return callback();
      });
    };
    buffer = [];
    session.on('message', bufferMsg = function(msg) {
      return buffer.push(msg);
    });
    model.clientConnect(data, function(error, client_) {
      var msg, _i, _len;
      if (error) {
        return client.stop();
      } else {
        client = client_;
        session.removeListener('message', bufferMsg);
        for (_i = 0, _len = buffer.length; _i < _len; _i++) {
          msg = buffer[_i];
          handleMessage(msg);
        }
        buffer = null;
        return session.on('message', handleMessage);
      }
    });
    return session.on('close', function() {
      var docName, listener;
      console.log("Client " + client.id + " disconnected");
      for (docName in docState) {
        listener = docState[docName].listener;
        if (listener) model.removeListener(docName, listener);
      }
      return docState = null;
    });
  });
};
