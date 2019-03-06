module bootstrap;

import grpc;
import hunt.net;

import TestRegistry;
import TestConfig;


int main()
{

    auto channel = new GrpcClient("127.0.0.1", 50051);
    NetUtil.startEventLoop();

    testRegistry(channel);
    testConfig(channel);
    return 0;
}