module bootstrap;

import grpc;
import hunt.net;
import neton.client.NetonFactory;
import neton.client.NetonOption;

import TestRegistry;
import TestConfig;


int main()
{

    NetonOption option = {"127.0.0.1", 50051};
    NetUtil.startEventLoop();

    // testRegistry(NetonFactory.createRegistryService(option));
    testConfig(NetonFactory.createConfigService(option));
    return 0;
}