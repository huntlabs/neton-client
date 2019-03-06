module client.NetonFactory;

import client.config.ConfigService;
import client.registry.RegistryService;
import client.NetonOption;
import grpc;

class NetonFactory
{
    static ConfigService createConfigService(NetonOption option)
    {
        auto channel = new GrpcClient(option.ip, option.port);
        return new ConfigService(channel);
    }

    static RegistryService createRegistryService(NetonOption option)
    {
        auto channel = new GrpcClient(option.ip, option.port);
        return new RegistryService(channel);
    }
}