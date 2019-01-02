
module clientv3.kvimpl;
import etcdserverpb.kv;
import etcdserverpb.rpc;
import etcdserverpb.rpcrpc;

import grpc;
import hunt.logging;

class KVImpl
{
    KVClient client;
    this(Channel channel)
    {
        client = new KVClient(channel);
    }

    bool get(string key , ref string value)
    {
        string[] values;
        if(!get(key , values))
            return false;
        if(values.length == 0)
            value = "";
        else
            value = values[0];
        return true;
    }

    bool get(string key , ref string[] values)
    {
        RangeRequest request = new RangeRequest();
        request.key = cast(ubyte[])key;
        ubyte[] end = cast(ubyte[])key.dup;
        end[$ - 1] += 1;
        request.rangeEnd = end;
        RangeResponse response;
        auto status = client.Range( request , response);
        if(!status.ok())
        {
            logError(status.errorMessage);
            return false;
        }

        foreach(v ; response.kvs)
        {
            values ~= cast(string)v.value;
        }

        return true;
    }


    bool put(string key , string value , long leaseID = 0)
    {
        PutRequest request = new PutRequest();
        request.key = cast(ubyte[])key;
        request.value = cast(ubyte[])value;
        request.lease = leaseID;
        PutResponse response;
        auto status = client.Put(request , response);
        if(!status.ok())
        {   
            logError(status.errorMessage);
            return false;
        }
        return true;
    }

    bool del(string key)
    {
        DeleteRangeRequest request = new DeleteRangeRequest();
        request.key = cast(ubyte[])key;

        DeleteRangeResponse response;
        auto status = client.DeleteRange(request , response);
        if(!status.ok())
        {
            logError(status.errorMessage);
            return false;
        }
        return true;
    }

}