module clientv3.watcher;


import etcdserverpb.kv;
import etcdserverpb.rpc;
import etcdserverpb.rpcrpc;
import grpc;
import core.time;

class Watcher
{
    ClientReaderWriter!(WatchResponse , WatchRequest) stream;
    
    bool watch(string key , ref long ID)
    {
        WatchRequest request = new WatchRequest();
        request. _requestUnionCase = WatchRequest.RequestUnionCase.createRequest;
        request._createRequest = new WatchCreateRequest();
        request._createRequest.key = cast(ubyte[])key;
        stream.write(request);
        WatchResponse response;
        stream.read(response);
        ID = response.watchId;
        return true;
    }

    bool cancel(long Id)
    {
        WatchRequest request = new WatchRequest();
        request. _requestUnionCase = WatchRequest.RequestUnionCase.cancelRequest;
        request._cancelRequest = new WatchCancelRequest();
        request._cancelRequest.watchId = Id;
        stream.write(request);
        stream.writesDone();
        WatchResponse response;
        stream.read(response);
        stream.finish();
        return true; 
    }

    this(ClientReaderWriter!(WatchResponse , WatchRequest) stream)
    {
        this.stream = stream;
    }

  
}