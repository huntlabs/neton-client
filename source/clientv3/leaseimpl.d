module clientv3.leaseimpl;
import etcdserverpb.kv;
import etcdserverpb.rpc;
import etcdserverpb.rpcrpc;

import grpc;
import hunt.logging;
import clientv3.keepalive;

class LeaseImpl
{
    class TimeToLiveRes
    {
        long ID;
        long TTL;
        long grantedTTL;
        string[] keys;
    }

    __gshared KeepAlive[long]   gkps_;
    immutable __gshared Object lock = new Object();


    LeaseClient     client;
    this(Channel channel)
    {
        client = new LeaseClient(channel);
    }

    bool grant( long ttl , ref long ID )
	{
        LeaseGrantRequest request = new LeaseGrantRequest();
        request.TTL = ttl;
        LeaseGrantResponse response;
        auto status = client.LeaseGrant(request , response);
        if(!status.ok())
        {
            logError(status.errorMessage);
            return false;
        }
        ID = response.ID;
        return true;
    }

	bool revoke( long ID)
	{
        LeaseRevokeRequest request = new LeaseRevokeRequest();
        request.ID = ID;
        LeaseRevokeResponse response;
        auto status = client.LeaseRevoke(request , response);
        if(!status.ok())
        {
            logError(status.errorMessage);
            return false;
        }
        return true;
	}

    bool openKeepalive(long ID )
    {
        synchronized(lock){
            if(ID in gkps_)
                return false;

            LeaseKeepAliveRequest request = new LeaseKeepAliveRequest();
            request.ID = ID;
            auto stream = client.LeaseKeepAlive();
            stream.write(request);
            LeaseKeepAliveResponse response;
            stream.read(response);

            gkps_[ID] = new KeepAlive(stream);
            gkps_[ID].start(request , response.TTL - 1);

            return true;
        }
    }

    bool closeKeepalive(long ID)
    {
        synchronized(lock){
            if(ID !in gkps_)
                return false;
            gkps_[ID].stop();
            gkps_.remove(ID);
            return true;
        }
    }

	bool timeToLive(long ID , out TimeToLiveRes res , bool keys = false )
	{
        LeaseTimeToLiveRequest request = new LeaseTimeToLiveRequest();
        request.ID = ID;
        request.keys = keys;

        LeaseTimeToLiveResponse response;
        auto status = client.LeaseTimeToLive(request , response);
        if(!status.ok())
        {
            logError(status.errorMessage);
            return false;
        }
        res = new TimeToLiveRes();
        res.ID = ID;
        res.TTL = response.TTL;
        res.grantedTTL = response.grantedTTL;
        foreach(k ; response.keys)
            res.keys ~= cast(string)k;
        return true;
    }

    bool leases(out long[] IDS)
    {
        LeaseLeasesResponse response;
        auto status = client.LeaseLeases(new LeaseLeasesRequest() , response);
        if(!status.ok())
        {
            logError(status.errorMessage);
            return false;
        }
        foreach(l ; response.leases)
            IDS ~= l.ID;
        return true;
    }
    
}