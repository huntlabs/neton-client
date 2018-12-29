module clientv3.keepalive;

import hunt.util.timer;
import hunt.event.timer;
import hunt.event.timer.common;
import core.thread;
import hunt.net;
import etcdserverpb.rpcrpc;
import etcdserverpb.rpc;
import grpc;
import core.time;

class KeepAlive 
{
    
    Timer           timer;
    ClientReaderWriter!(LeaseKeepAliveResponse,LeaseKeepAliveRequest) stream;

    this(ClientReaderWriter!(LeaseKeepAliveResponse,LeaseKeepAliveRequest) stream)
    {
        this.stream = stream;
    }

    bool start(LeaseKeepAliveRequest request , long seconds)
    {
        LeaseKeepAliveResponse response;
        timer = new Timer(NetUtil.defaultEventLoopGroup().nextLoop() , dur!"seconds"(seconds));
        timer.onTick(
           (Object sender) {
               stream.write(request);
               stream.read(response);
            }
        );
        timer.start();
        return true;
    }


    bool stop()
    {
        timer.stop();
        stream.writesDone();
        auto status = stream.finish(); 
        return status.ok();   
    }
}