module client.registry.HeartBeat;

import hunt.logging;
import grpc;
import etcdserverpb.kv;
import etcdserverpb.rpc;
import etcdserverpb.rpcrpc;

import hunt.concurrency.ScheduledThreadPoolExecutor;
import hunt.concurrency.ThreadPoolExecutor;
import hunt.concurrency.Executors;
import hunt.concurrency.ExecutorService;
import hunt.concurrency.Future;
import hunt.util.Common;
import core.time;
import std.stdio;

class HeartBeat
{
    private
    {
        LeaseClient _client;
        long _leaseID;
        ScheduledThreadPoolExecutor _executor;
    }

    this(Channel channel)
    {
        _client = new LeaseClient(channel);
        _executor = cast(ScheduledThreadPoolExecutor) Executors.newScheduledThreadPool(1);
    }

    bool grant(long ttl, ref long ID)
    {
        assert(ttl > 1);

        LeaseGrantRequest request = new LeaseGrantRequest();
        request.TTL = ttl;
        request.ID = ID;

        LeaseGrantResponse response = _client.LeaseGrant(request);
        if (response is null)
        {
            logError("LeaseGrant error : ",ID);
            return false;
        }
        ID = response.ID;
        _leaseID = ID;
        return true;
    }

    void start()
    {
        synchronized (this)
        {
            LeaseKeepAliveRequest request = new LeaseKeepAliveRequest();
            request.ID = _leaseID;
            auto stream = _client.LeaseKeepAlive();
            stream.write(request);
            LeaseKeepAliveResponse response;
            stream.read(response);

            _executor.scheduleAtFixedRate(new HeartBeatTask(stream,request),
                    seconds(response.TTL/2 + 1), seconds(response.TTL - 1));
        }
    }

    bool stop()
    {
        synchronized (this)
        {
            writeln("------ stop heartBeat : ",_leaseID);
            _executor.shutdown();
            LeaseRevokeRequest request = new LeaseRevokeRequest();
            request.ID = _leaseID;
            LeaseRevokeResponse response = _client.LeaseRevoke(request);
            if (response is null)
            {
                logError("LeaseRevoke error : ",_leaseID);
                return false;
            }
            return true;
        }
    }
}

class HeartBeatTask : Runnable
{
    private
    {
        LeaseKeepAliveRequest _request;
        ClientReaderWriter!(LeaseKeepAliveResponse,LeaseKeepAliveRequest) _stream;
    }

    this(ClientReaderWriter!(LeaseKeepAliveResponse,LeaseKeepAliveRequest) stream, LeaseKeepAliveRequest req)
    {
        _stream = stream;  
        _request = req;
    }

    void run()
    {
        writeln("send heart beat : ",_request.ID);
        LeaseKeepAliveResponse response;
        _stream.write(_request);
        _stream.read(response);
    }

}
