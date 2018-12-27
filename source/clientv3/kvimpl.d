
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
        RangeRequest request = new RangeRequest();
        request.key = cast(ubyte[])key;
        request.limit = 1;
        RangeResponse response;
        auto status = client.Range( request , response);
        if(!status.ok())
        {
            logError(status.errorMessage);
            return false;
        }
        if(response.count == 0)
            value = "";
        else
            value = cast(string)response.kvs[0].value;
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