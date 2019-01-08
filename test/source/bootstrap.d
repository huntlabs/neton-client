module bootstrap;

import testkv;
import testlease;
import testwatch;
import testservice;
import grpc;
import hunt.net;

int main()
{

    auto channel = new GrpcClient("127.0.0.1", 50051);
    NetUtil.startEventLoop();
    testKV(channel);
    testLease(channel);
    testWatch(channel);
    testService(channel);
    return 0;
}