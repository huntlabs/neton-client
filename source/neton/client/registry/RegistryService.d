module neton.client.registry.RegistryService;

import neton.protocol.neton;
import neton.protocol.neton;
import neton.protocol.netonrpc;

import grpc;
import hunt.logging;
import hunt.util.Serialize;
import std.conv;
import std.json;

import neton.client.registry.Instance;
import neton.client.Listener;
import neton.client.WatchFactory;
import neton.client.Watcher;
import neton.client.registry.HeartBeat;

enum HEART_TTL = 60; ///seconds

class RegistryService
{
    private
    {
        RegistryClient _client;
        Watcher _watcher;
        HeartBeat[long] _heartBeatMap;
        Channel _channel;
    }

    public this(Channel chanel)
    {
        _channel = chanel;
        _client = new RegistryClient(chanel);
        _watcher = WatchFactory.createRegistryWatcher(chanel, "/service");
    }

    ~this()
    {
        if(_heartBeatMap.length > 0)
        {
            foreach(long leaseId , HeartBeat hb; _heartBeatMap) {
                hb.stop();
            }
            _heartBeatMap.clear();
        }
    }

    bool registerInstance(string serviceName, string ip, short port)
    {
        logInfo("registerInstance : ",serviceName);

        try
        {
            string regKey = serviceName ~ "/" ~ ip ~ ":" ~ to!string(port);
            long leaseID = hashOf(regKey);
            if (leaseID in _heartBeatMap)
            {
                logErrorf("%s have already registered!", regKey);
                return false;
            }
            auto heartBeat = new HeartBeat(_channel);
            heartBeat.grant(HEART_TTL, leaseID);

            Instance instant = {serviceName, ip, port};

            PutRequest request = new PutRequest();
            request.key = cast(ubyte[])(regKey);
            request.value = cast(ubyte[])(toJson(instant).toString);
            request.lease = leaseID;
            assert(request.key.length != 0);

            PutResponse response = _client.Put(request);
            if (response is null)
            {
                logError("response is null");
                return false;
            }
            _heartBeatMap[leaseID] = heartBeat;
            heartBeat.start();

            return true;
        }
        catch (Throwable e)
        {
            logError("RegistryService : ", e.msg);
            return false;
        }
    }

    bool deregisterInstance(string serviceName, string ip, short port)
    {
        logInfo("deregisterInstance : ",serviceName);
        try
        {
            string regKey = serviceName ~ "/" ~ ip ~ ":" ~ to!string(port);
            long leaseID = hashOf(regKey);

            DeleteRangeRequest request = new DeleteRangeRequest();
            request.key = cast(ubyte[])(regKey);
            assert(request.key.length != 0);

            DeleteRangeResponse response = _client.DeleteRange(request);
            if (response is null)
            {
                logError("response is null");
                return false;
            }
            if (leaseID in _heartBeatMap)
            {
                _heartBeatMap[leaseID].stop();
                _heartBeatMap.remove(leaseID);
            }
            return true;
        }
        catch (Throwable e)
        {
            logError("RegistryService : ", e.msg);
            return false;
        }

    }

    Instance[] getAllInstances(string serviceName)
    {
        logInfo("getAllInstances : ",serviceName);
        try
        {
            RangeRequest request = new RangeRequest();
            request.key = cast(ubyte[]) serviceName;
            // ubyte[] end = cast(ubyte[]) serviceName.dup;
            // end[$ - 1] += 1;
            // request.rangeEnd = end;
            assert(request.key.length != 0);

            RangeResponse response = _client.Range(request);
            if (response is null)
            {
                logError("response is null");
                return null;
            }
            Instance[] values;
            foreach (v; response.kvs)
            {
                values ~= toObject!Instance(parseJSON(cast(string) v.value));
            }
            return values;
        }
        catch (Throwable e)
        {
            logError("RegistryService : ", e.msg);
            return null;
        }

    }

    void subscribe(string serviceName, Listener listener)
    {
        logInfo("subscribe : ",serviceName);
        synchronized (this)
        {
            _watcher.watch(serviceName, listener);
        }
    }

    void unsubscribe(string serviceName, Listener listener)
    {
        logInfo("unsubscribe : ",serviceName);
        synchronized (this)
        {
            _watcher.cancel(serviceName, listener);
        }
    }

}
