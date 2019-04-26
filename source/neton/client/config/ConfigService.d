module neton.client.config.ConfigService;

import neton.protocol.neton;
import neton.protocol.neton;
import neton.protocol.netonrpc;
import neton.client.Listener;
import neton.client.WatchFactory;
import neton.client.Watcher;
import grpc;
import hunt.logging;

class ConfigService
{
    private
    {
        ConfigClient _client;
        Watcher _watcher;
    }

    public this(Channel chanel)
    {
        _client = new ConfigClient(chanel);
        _watcher = WatchFactory.createConfigWatcher(chanel, "/config");
    }

    public string getConfig(string config, long timeoutMs = 0)
    {
        logInfo("getConfig : ",config);
        try
        {
            RangeRequest request = new RangeRequest();
            request.key = cast(ubyte[]) config;
            // ubyte[] end = cast(ubyte[]) config.dup;
            // end[$ - 1] += 1;
            // request.rangeEnd = end;
            assert(request.key.length != 0);
            RangeResponse response = _client.Range(request);
            if (response is null)
            {
                logError("response is null");
                return string.init;
            }
            string[] values;
            foreach (v; response.kvs)
            {
                values ~= cast(string) v.value;
            }

            return values.length > 0 ? values[0] : string.init;
        }
        catch (Throwable e)
        {
            logError("ConfigService : ", e.msg);
            return string.init;
        }
    }

    public bool publishConfig(string config, string content)
    {
        logInfo("publishConfig : ",config);

        try
        {
            PutRequest request = new PutRequest();
            request.key = cast(ubyte[]) config;
            request.value = cast(ubyte[]) content;
            request.lease = 0;
            assert(request.key.length != 0);
            PutResponse response = _client.Put(request);
            if (response is null)
            {
                logError("response is null");
                return false;
            }
            return true;
        }
        catch (Throwable e)
        {
            logError("ConfigService : ", e.msg);
            return false;
        }

    }

    public bool removeConfig(string config)
    {
        logInfo("removeConfig : ",config);
        try
        {
            DeleteRangeRequest request = new DeleteRangeRequest();
            request.key = cast(ubyte[]) config;
            assert(request.key.length != 0);

            DeleteRangeResponse response = _client.DeleteRange(request);
            if (response is null)
            {
                logError("response is null");
                return false;
            }
            return true;
        }
        catch (Throwable e)
        {
            logError("ConfigService : ", e.msg);
            return false;
        }
    }

    public void addListener(string config, Listener listener)
    {
        synchronized (this)
        {
            _watcher.watch(config, listener);
        }
    }

    public void removeListener(string config, Listener l)
    {
        synchronized (this)
        {
            _watcher.cancel(config, l);
        }
    }
}
