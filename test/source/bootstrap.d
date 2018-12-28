module bootstrap;

import testkv;
import testlease;
import testwatch;
import grpc;
import hunt.net;

int main()
{

    auto channel = new GrpcClient("127.0.0.1", 2379);
    NetUtil.startEventLoop();
    testKV(channel);
    testLease(channel);
    testWatch(channel);
    return 0;
}