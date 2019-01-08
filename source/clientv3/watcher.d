module clientv3.watcher;


import etcdserverpb.kv;
import etcdserverpb.rpc;
import etcdserverpb.rpcrpc;
import grpc;
import core.time;
import util.future;
import hunt.logging;
import clientv3.watchimpl;
import core.thread;

class Watcher
{
    ClientReaderWriter!(WatchResponse , WatchRequest)   stream;         
    Future!(int , WatchResponse)[]                      creates;
    Future!(int , WatchResponse)[]                      cancels;
    
    bool watch(string key , ref long ID)
    {
        WatchRequest request = new WatchRequest();
        request. _requestUnionCase = WatchRequest.RequestUnionCase.createRequest;
        request._createRequest = new WatchCreateRequest();
        request._createRequest.key = cast(ubyte[])key;
        ubyte[] end = cast(ubyte[])key.dup;
         request._createRequest.rangeEnd = end;
        end[$ - 1] += 1;
        stream.write(request);
        auto f = new Future!(int ,WatchResponse)(0);
        creates ~= f;
        WatchResponse response = f.get();
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
        auto f = new Future!(int , WatchResponse)(0);
        cancels ~= f;
        f.get();
        return true;
    }

    this(ClientReaderWriter!(WatchResponse , WatchRequest) stream , WatchNotify notify)
    {
        this.stream = stream;

        new Thread((){
            WatchResponse response;
            try{
                while(stream.read(response))
                {
                    logError("begin " , );
                    if(response.created)
                    {
                        logError("created " , response.watchId);
                        creates[0].done(response);
                        creates = creates[1 .. $];               
                    }
                    else if(response.canceled)  
                    {
                        logError("canceled " , response.watchId);
                        cancels[0].done(response);
                        cancels = cancels[1 .. $];
                    }
                    else{
                        logError("other ");
                        foreach(e ; response.events)
                        {
                            auto item = new WatchImpl.NotifyItem();
                            item.ID = response.watchId;
                            item.key = cast(string)e.kv.key;
                            item.value = cast(string)e.kv.value;
                            item.op = e.type;
                            logError("errr start " , response.watchId);
                            notify(item);
                            logError("errr end " , response.watchId);
                        }    
                    }
                    logError("end");
                }
            }catch(Throwable e){
                logError(e.msg);
            }
            logError("in false");
        }).start();
    }



    bool close()
    {
        stream.writesDone();
        return stream.finish().ok();
    }

  
}