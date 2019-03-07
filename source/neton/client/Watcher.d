module neton.client.Watcher;

import neton.protocol.neton;
import neton.protocol.neton;
import neton.protocol.netonrpc;
import neton.client.Listener;
import neton.client.Event;
import neton.util.future;
import grpc;
import hunt.logging;
import core.thread;
import std.algorithm.mutation;
import std.stdio;

class Watcher
{
    private
    {
        string _prefix;

        ClientReaderWriter!(WatchResponse, WatchRequest) _stream;
        Future!(int, WatchResponse) _createWatch;
        Future!(int, WatchResponse) _cancelWatch;
        Listener[][long] _listenMap;
        long[string] _keyWatchIdMap;

    }

    long watch(string key, Listener lit)
    {
        writefln("watch key: %s , listener :%s ", key, lit);
        string configKey = _prefix ~ "/" ~ key;
        if (key in _keyWatchIdMap)
        {
            auto id = _keyWatchIdMap[key];
            if (id in _listenMap)
            {
                _listenMap[id] ~= lit;
                return id;
            }
            else
            {
                _keyWatchIdMap.remove(key);
            }
        }

        WatchRequest request = new WatchRequest();
        request._requestUnionCase = WatchRequest.RequestUnionCase.createRequest;
        request._createRequest = new WatchCreateRequest();
        request._createRequest.key = cast(ubyte[]) configKey;
        ubyte[] end = cast(ubyte[]) configKey.dup;
        request._createRequest.rangeEnd = end;
        end[$ - 1] += 1;
        _stream.write(request);

        auto f = new Future!(int, WatchResponse)(0);
        _createWatch = f;
        WatchResponse response = f.get();
        auto id = response.watchId;
        _listenMap[id] ~= lit;
        _keyWatchIdMap[key] = id;
        return id;
    }

    bool cancel(string key, Listener listener)
    {
        writefln("cancel watch key: %s , listener :%s ", key, listener);

        long id;
        if (key in _keyWatchIdMap)
        {
            id = _keyWatchIdMap[key];
            // logError("before cancel size : ", _listenMap[id].length);
            _listenMap[id] = remove!(a => a is listener)(_listenMap[id]);
            // logError("after cancel size : ", _listenMap[id].length);
            if (_listenMap[id].length > 0)
                return true;
        }
        else
            return false;
        WatchRequest request = new WatchRequest();
        request._requestUnionCase = WatchRequest.RequestUnionCase.cancelRequest;
        request._cancelRequest = new WatchCancelRequest();
        request._cancelRequest.watchId = id;
        _stream.write(request);
        auto f = new Future!(int, WatchResponse)(0);
        _cancelWatch = f;
        f.get();
        return true;
    }

    this(ClientReaderWriter!(WatchResponse, WatchRequest) stream, string prefix)
    {
        this._stream = stream;
        this._prefix = prefix;

        new Thread(() {
            WatchResponse response;
            try
            {
                while (_stream.read(response))
                {
                    // logError("begin ",);
                    if (response.created)
                    {
                        // logError("created ", response.watchId);
                        _createWatch.done(response);
                    }
                    else if (response.canceled)
                    {
                        // logError("canceled ", response.watchId);
                        _cancelWatch.done(response);
                    }
                    else
                    {
                        // logError("other ");
                        foreach (neton.protocol.neton.Event e; response.events)
                        {
                            neton.client.Event.Event event;
                            event.key = cast(string) e.kv.key;
                            event.value = cast(string) e.kv.value;
                            auto type = cast(int)(e.type);
                            event.type = cast(neton.client.Event.Event.EventType) type;
                            auto id = response.watchId;
                            // logError("errr start ", response.watchId);
                            if (id in _listenMap)
                            {
                                foreach (listener; _listenMap[id])
                                    listener.onEvent(event);
                            }
                            // logError("errr end ", response.watchId);
                        }
                    }
                    // logError("end");
                }
            }
            catch (Throwable e)
            {
                logError(e.msg);
            }
            // logError("in false");
        }).start();
    }

    bool close()
    {
        _stream.writesDone();
        return _stream.finish().ok();
    }

}
